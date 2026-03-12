import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 1. Fetch User Data from Supabase
  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      setState(() {
        _userData = data;
      });
    }
  }

  // 2. Update Safety Preferences
  Future<void> _updatePreference(String key, bool value) async {
    setState(() => _userData![key] = value);
    final user = Supabase.instance.client.auth.currentUser;
    
    // Update Supabase Database
    await Supabase.instance.client.from('profiles').update({key: value}).eq('id', user!.id);
    
    // If connected to ESP32, send the updated settings immediately!
    if (_connectedDevice != null) {
      _sendDataToESP32(_connectedDevice!);
    }
  }

  // 3. Start Scanning for Bluetooth Devices
  Future<void> _startScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bluetooth not supported')));
      return;
    }

    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    FlutterBluePlus.onScanResults.listen((results) {
      setState(() {
        _scanResults = results;
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // 4. Connect to the Selected Device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    setState(() => _isScanning = false);

    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connecting to ${device.platformName.isEmpty ? "Device" : device.platformName}...')));
      
      await device.connect();
      
      setState(() {
        _connectedDevice = device;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connected! Syncing data...'), backgroundColor: Colors.green));
      
      await _sendDataToESP32(device);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to connect: $e'), backgroundColor: Colors.red));
    }
  }

  // 5. Send Data to ESP32
  Future<void> _sendDataToESP32(BluetoothDevice device) async {
    if (_userData == null) return;

    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            
            // Create JSON string with user data and safety toggles
            String dataToSend = jsonEncode({
              "name": _userData!['full_name'],
              "contacts": _userData!['emergency_contacts'], // Sends the whole JSON array
              "voice_sos": _userData!['voice_sos'] ?? true,
              "motion": _userData!['motion_detection'] ?? true,
              "button": _userData!['button_sos'] ?? true,
            });

            await characteristic.write(utf8.encode(dataToSend));
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data synced to wristband successfully!'), backgroundColor: Colors.green),
            );
            return; 
          }
        }
      }
    } catch (e) {
      print("Error sending data: $e");
    }
  }

  // 6. Disconnect Device
  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device Disconnected')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SheBand Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigate to Edit Profile and refresh data when coming back
              await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(userData: _userData!)));
              _fetchUserData(); 
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP SECTION: Greeting, Toggles, and BT Card (Scrollable if screen is small)
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome, ${_userData!['full_name']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),

                    // Safety Preferences Toggles
                    const Text('Safety Features Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Hardware Button SOS'),
                      value: _userData!['button_sos'] ?? true,
                      onChanged: (val) => _updatePreference('button_sos', val),
                      activeColor: Colors.pinkAccent,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Motion/Shake Detection'),
                      value: _userData!['motion_detection'] ?? true,
                      onChanged: (val) => _updatePreference('motion_detection', val),
                      activeColor: Colors.pinkAccent,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Voice SOS Detection'),
                      value: _userData!['voice_sos'] ?? true,
                      onChanged: (val) => _updatePreference('voice_sos', val),
                      activeColor: Colors.pinkAccent,
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    const Divider(height: 32),

                    // Connection Status Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _connectedDevice != null ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _connectedDevice != null ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                            size: 48,
                            color: _connectedDevice != null ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _connectedDevice != null 
                                ? 'Connected to: ${_connectedDevice!.platformName.isNotEmpty ? _connectedDevice!.platformName : "ESP32"}' 
                                : 'No Device Connected',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          if (_connectedDevice == null)
                            ElevatedButton.icon(
                              onPressed: _isScanning ? null : _startScan,
                              icon: _isScanning 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                  : const Icon(Icons.search),
                              label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: _disconnectDevice,
                              icon: const Icon(Icons.bluetooth_disabled),
                              label: const Text('Disconnect'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // BOTTOM SECTION: List of Scanned Devices
            if (_connectedDevice == null) ...[
              const SizedBox(height: 16),
              const Text('Available Devices:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: _scanResults.isEmpty 
                  ? const Center(child: Text('No devices found. Press Scan.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _scanResults.length,
                      itemBuilder: (context, index) {
                        final result = _scanResults[index];
                        final deviceName = result.device.platformName.isNotEmpty 
                            ? result.device.platformName 
                            : 'Unknown Device';
                        final macAddress = result.device.remoteId.toString();

                        return Card(
                          color: const Color(0xFF2A2A2A),
                          child: ListTile(
                            leading: const Icon(Icons.bluetooth, color: Colors.blueAccent),
                            title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(macAddress, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () => _connectToDevice(result.device),
                              child: const Text('Connect'),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}