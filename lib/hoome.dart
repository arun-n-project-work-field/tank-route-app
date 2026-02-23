import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:tankroute/user_info.dart';

class HomeScreens extends StatefulWidget {
  final String name;
  final String phoneNumber;

  const HomeScreens({
    super.key,
    required this.name,
    required this.phoneNumber,
  });

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  // ------------------------
  // Variables
  // ------------------------

  final String uniqueId = '38811737-34d3-3c0c-bdfa-91a7b0f4057b';

  String currentTime = '';
  double? latitude;
  double? longitude;

  String? selectedTank;

  final List<String> tankList = [
    "Tank A",
    "Tank B",
    "Tank C",
    "Tank D",
  ];

  // ------------------------
  // INIT
  // ------------------------

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    _getCurrentTime();
    await _getCurrentLocation();
  }

  // ------------------------
  // TIME
  // ------------------------

  void _getCurrentTime() {
    final now = DateTime.now();
    final formatted = DateFormat('dd-MM-yyyy  HH:mm:ss').format(now);

    if (!mounted) return;

    setState(() {
      currentTime = formatted;
    });
  }

  // ------------------------
  // LOCATION
  // ------------------------

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
          'Location permanently denied. Enable from settings.');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }

  // ------------------------
  // UI HELPERS
  // ------------------------

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to Logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserInfoScreen(),
                ),
              );
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label : ",
            style: const TextStyle(
              color: Colors.lightGreenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildLocationValue(double? value) {
    if (value == null) {
      return const SizedBox(
        width: 15,
        height: 15,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Text(
      value.toString(),
      style: const TextStyle(
        color: Colors.cyanAccent,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ------------------------
  // BUILD
  // ------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tank Info"),
        backgroundColor: Colors.blueAccent,
        actions: [
          TextButton(
            onPressed: _showLogoutDialog,
            child: const Text(
              "LOGOUT",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // ------------------------
            // USER SECTION
            // ------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1C2B17),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Name: ${widget.name}",
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Mobile: ${widget.phoneNumber}",
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ------------------------
            // INFO CARD
            // ------------------------

            Card(
              margin: const EdgeInsets.all(12),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildInfoRow(
                      "Unique ID",
                      Text(
                        uniqueId,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    _buildInfoRow(
                      "Time",
                      Text(
                        currentTime,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    _buildInfoRow("Latitude", _buildLocationValue(latitude)),
                    _buildInfoRow("Longitude", _buildLocationValue(longitude)),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ------------------------
            // TANK DROPDOWN
            // ------------------------

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Select Tank Name",
                  border: OutlineInputBorder(),
                ),
                value: selectedTank,
                items: tankList.map((tank) {
                  return DropdownMenuItem(
                    value: tank,
                    child: Text(tank),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTank = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            if (selectedTank != null)
              Text(
                "Selected Tank: $selectedTank",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
