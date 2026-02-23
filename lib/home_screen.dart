import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tankroute/user_info.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'device_id_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final String name;
  final String phoneNumber;

  const HomeScreen({super.key, required this.name, required this.phoneNumber});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? deviceId;
  String currentTime = '';
  double? latitude;
  double? longitude;
  String? selectedTank;
  bool _isMapLoading = true;
  bool _isFetchingTank = false;

  // final List<String> tankList = ["Tank A", "Tank B", "Tank C", "Tank D"];

  final Map<String, Map<String, String>> tankInfo = {
    "Tank A": {
      "KGIS Tank ID": "3224",
      "Unique Tank": "KA20010002",
      "Tank Area": "5.03159571",
      "Latitude": "13.01088494",
      "Longitude": "77.48624457",
    },
    "Tank B": {
      "KGIS Tank ID": "3225",
      "Unique Tank": "KA20010003",
      "Tank Area": "6.123456",
      "Latitude": "13.02088494",
      "Longitude": "77.49624457",
    },
    "Tank C": {
      "KGIS Tank ID": "3226",
      "Unique Tank": "KA20010004",
      "Tank Area": "7.234567",
      "Latitude": "13.03088494",
      "Longitude": "77.50624457",
    },
    "Tank D": {
      "KGIS Tank ID": "3227",
      "Unique Tank": "KA20010005",
      "Tank Area": "8.345678",
      "Latitude": "13.04088494",
      "Longitude": "77.51624457",
    },
  };
  List<String> tankList = [];

  List<String> filteredList = [];
  final FocusNode _tankFocusNode = FocusNode();
  final TextEditingController _tankController = TextEditingController();
  final MapController _mapController = MapController();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    _loadTankNames();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
      _loadDeviceId();
    });

    _tankFocusNode.addListener(() {
      if (_tankFocusNode.hasFocus) {
        _filterList(_tankController.text);
      } else {
        _removeOverlay();
      }
      setState(() {});
    });
  }

  Future<void> _loadDeviceId() async {
    final id = await DeviceIdService.getOrCreateDeviceId();
    if (!mounted) return;
    setState(() => deviceId = id);
  }

  Future<void> _initializeScreen() async {
    _getCurrentTime();
    await _getCurrentLocation();
  }

  void _getCurrentTime() {
    final now = DateTime.now();
    final formatted = DateFormat('dd-MM-yyyy  HH:mm:ss').format(now);
    if (!mounted) return;
    setState(() => currentTime = formatted);
  }

  void _goToCurrentLocation() {
    if (latitude != null && longitude != null) {
      _mapController.move(
        LatLng(latitude!, longitude!),
        16, // zoom level
      );
    } else {
      _showSnackBar("Current location not available");
    }
  }

  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     _showSnackBar('Location services are disabled.');
  //     return;
  //   }
  //
  //   LocationPermission permission = await Geolocator.checkPermission();
  //
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       _showSnackBar('Location permission denied.');
  //       return;
  //     }
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) {
  //     _showSnackBar('Location permanently denied.');
  //     return;
  //   }
  //
  //   final position = await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high,
  //   );
  //
  //   if (!mounted) return;
  //
  //   setState(() {
  //     latitude = position.latitude;
  //     longitude = position.longitude;
  //   });
  // }
  //
  // void _showSnackBar(String message) {
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(SnackBar(content: Text(message)));
  // }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Location permissions are permanently denied.');
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

    // Move camera to user location
    _mapController.move(LatLng(latitude!, longitude!), 15.0);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final Uri uri = Uri.parse(
      'google.navigation:q=$latitude,$longitude&mode=d',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Google Maps not available');
    }
  }

  void _filterList(String input) {
    if (input.isEmpty) {
      filteredList = List.from(tankList);
    } else {
      filteredList = tankList
          .where((tank) => tank.toLowerCase().contains(input.toLowerCase()))
          .toList();
    }

    if (_tankFocusNode.hasFocus) {
      if (_overlayEntry == null) {
        _showOverlay();
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _loadTankNames() async {
    final url = Uri.parse(
      "https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/0/query"
          "?where=1=1"
          "&outFields=TankName"
          "&returnGeometry=false"
          "&f=pjson",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["features"] != null) {
          final List features = data["features"];

          tankList = features
              .map((f) => f["attributes"]["TankName"].toString())
              .where((name) => name.isNotEmpty)
              .toList();

          filteredList = List.from(tankList);

          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      // silently fail
    }
  }


  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _tankFocusNode.unfocus();
          _removeOverlay();
        },
        child: Center(
          child: Material(
            elevation: 4,
            color: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 300,
                minWidth: 200,
                maxWidth: 300,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  return ListTile(
                    title: Text(item),
                    onTap: () {
                      _tankController.text = item;
                      selectedTank = item;
                      _tankFocusNode.unfocus();
                      _removeOverlay();
                      setState(() {});
                      _fetchTankByName(item);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // cannot close manually
      builder: (_) => const AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        content: SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  // void _showTankDialog(String item) {
  //   final info = tankInfo[item];
  //   if (info == null) return;
  //
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       backgroundColor: Colors.white,
  //       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  //       title: const Text(
  //         "Tank Information",
  //         style: TextStyle(fontWeight: FontWeight.bold),
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text("Tank Name : $item"),
  //           const SizedBox(height: 15),
  //           Text("KGIS Tank ID : ${info["KGIS Tank ID"]}"),
  //           Text("Unique Tank : ${info["Unique Tank"]}"),
  //           Text("Tank Area : ${info["Tank Area"]}"),
  //           Text("Latitude : ${info["Latitude"]}"),
  //           Text("Longitude : ${info["Longitude"]}"),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text(
  //             "CLOSE",
  //             style: TextStyle(
  //               color: Colors.blueAccent,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             final lat = double.tryParse(info["Latitude"] ?? '');
  //             final lng = double.tryParse(info["Longitude"] ?? '');
  //             if (lat != null && lng != null) {
  //               _openGoogleMaps(lat, lng);
  //             }
  //           },
  //           child: const Text(
  //             "NAVIGATE",
  //             style: TextStyle(
  //               color: Colors.blueAccent,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _fetchTankByName(String tankName) async {
    if (_isFetchingTank) return;

    _isFetchingTank = true;
    _showLoadingDialog();

    final url = Uri.parse(
      "https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/0/query"
          "?where=TankName='$tankName'"
          "&outFields=*"
          "&returnGeometry=false"
          "&f=pjson",
    );

    try {
      final response = await http.get(url);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["features"] != null &&
            data["features"].isNotEmpty) {

          final attributes = data["features"][0]["attributes"];
          _showTankDialogDynamic(attributes);

        } else {
          _showNoTankDialog();
        }
      } else {
        _showNoTankDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showNoTankDialog();
      }
    }

    _isFetchingTank = false;
  }


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to Logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UserInfoScreen()),
              );
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationValue(double? value) {
    if (value == null) {
      return const SizedBox(
        width: 15,
        height: 15,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    return Text(
      value.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 8,
      ),
    );
  }

  void _resetMap() {
    // Reset map position
    _mapController.move(LatLng(latitude!, longitude!), 15.0);

    // Clear tank selection
    _tankController.clear();
    selectedTank = null;

    // Remove dropdown overlay
    _removeOverlay();

    setState(() {});
  }

  // void _handleMapTap(LatLng point) {
  //   final lat = point.latitude;
  //   final lng = point.longitude;
  //
  //   // 🔹 First show lat-long
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  //       title: const Text("Selected Location"),
  //       content: Text("Latitude: $lat\nLongitude: $lng"),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("GET TANK INFO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   // 🔹 OPTIONAL: Check polygon hit
  //   // _checkIfInsidePolygon(point);
  // }

  void _handleMapTap(LatLng point) {
    if (_isFetchingTank) return;
    final lat = point.latitude;
    final lng = point.longitude;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text("Selected Location"),
        content: Text("Latitude: $lat\nLongitude: $lng"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchTankInfo(point);
            },
            child: const Text(
              "GET TANK INFO",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Future<void> _fetchTankInfo(LatLng point) async {
  //
  //   final url = Uri.parse(
  //     "https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/0/query"
  //         "?geometry=${point.longitude},${point.latitude}"
  //         "&geometryType=esriGeometryPoint"
  //         "&inSR=4326"
  //         "&spatialRel=esriSpatialRelIntersects"
  //         "&outFields=*"
  //         "&returnGeometry=false"
  //         "&f=pjson",
  //   );
  //
  //   try {
  //     final response = await http.get(url);
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //
  //       if (data["features"] != null &&
  //           data["features"].isNotEmpty) {
  //
  //         final attributes = data["features"][0]["attributes"];
  //
  //         _showTankDialogDynamic(attributes);
  //
  //       } else {
  //         _showNoTankDialog();
  //       }
  //     } else {
  //       _showNoTankDialog();
  //     }
  //   } catch (e) {
  //     _showNoTankDialog();
  //   }
  // }

  Future<void> _fetchTankInfo(LatLng point) async {
    if (_isFetchingTank) return;

    _isFetchingTank = true;

    _showLoadingDialog();

    final url = Uri.parse(
      "https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/0/query"
          "?geometry=${point.longitude},${point.latitude}"
          "&geometryType=esriGeometryPoint"
          "&inSR=4326"
          "&spatialRel=esriSpatialRelIntersects"
          "&outFields=*"
          "&returnGeometry=false"
          "&f=pjson",
    );

    try {
      final response = await http.get(url);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop(); // ✅ force close loader

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["features"] != null &&
            data["features"].isNotEmpty) {

          final attributes = data["features"][0]["attributes"];
          _showTankDialogDynamic(attributes);

        } else {
          _showNoTankDialog();
        }
      } else {
        _showNoTankDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showNoTankDialog();
      }
    }

    _isFetchingTank = false; // ✅ unlock taps
  }


  void _showTankDialogDynamic(Map attributes) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: const Text(
          "Tank Information",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tank Name : ${attributes["TankName"] ?? "N/A"}"),
              const SizedBox(height: 15),
              Text("KGIS Tank ID : ${attributes["KGISTankID"] ?? "N/A"}"),
              Text("Unique Tank : ${attributes["UniqueTank"] ?? "N/A"}"),
              Text("Tank Area (Ha) : ${attributes["TankArea_H"] ?? "N/A"}"),
              Text("Latitude : ${attributes["Latitude"] ?? "N/A"}"),
              Text("Longitude : ${attributes["Longitude"] ?? "N/A"}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CLOSE",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              final lat = attributes["Latitude"];
              final lng = attributes["Longitude"];

              if (lat != null && lng != null) {
                _openGoogleMaps(
                  double.parse(lat.toString()),
                  double.parse(lng.toString()),
                );
              }
            },
            child: const Text(
              "NAVIGATE",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoTankDialog() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: Text("No Tank Found"),
        content: Text("No tank exists at this location."),
      ),
    );
  }

  @override
  void dispose() {
    _tankFocusNode.dispose();
    _tankController.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text(
            "Tank Info",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(4.0),
            child: CircleAvatar(foregroundColor: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: _showLogoutDialog,
              child: const Text(
                "LOGOUT",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            SizedBox(height: 2),
            Container(
              color: Colors.blueAccent,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      FutureBuilder<String>(
                        future: DeviceIdService.getOrCreateDeviceId(),
                        builder: (context, snapshot) {
                          String displayText;

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            displayText = "Loading...";
                          } else if (snapshot.hasError) {
                            displayText = "Error";
                          } else {
                            displayText = snapshot.data ?? "Unknown UUID";
                          }

                          return Text(
                            displayText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          );
                        },
                      ),
                      Row(
                        children: [
                          Text(
                            currentTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildLocationValue(latitude),
                          const Text(
                            ",  ",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                          _buildLocationValue(longitude),
                        ],
                      ),
                    ],
                  ),

                  Text(
                    "V- V-1.0",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2),
            Container(
              color: Color(0xFF1B2A00),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Text(
                      "    Name : ",
                      style: const TextStyle(
                        color: Colors.lightGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Text(
                      "Mobile No : ",
                      style: const TextStyle(
                        color: Colors.lightGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.phoneNumber,
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 2),
            Container(
              color: Colors.blueAccent,
              width: double.infinity,
              child: Text(
                textAlign: TextAlign.center,
                "Click the Tank Location on the map/Select the Tank Name from dropdown to know the Tank Information",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            // Expanded(
            //   child: FlutterMap(
            //     mapController: _mapController,
            //     options: const MapOptions(
            //       initialCenter: LatLng(13.01088494, 77.48624457),
            //       initialZoom: 12,
            //     ),
            //     children: [
            //       TileLayer(
            //         urlTemplate:
            //             'https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/tile/{z}/{y}/{x}',
            //         userAgentPackageName: 'com.example.app',
            //       ),
            //     ],
            //   ),
            // ),
            // Expanded(
            //   child: Stack(
            //     children: [
            // FlutterMap(
            //   mapController: _mapController,
            //   options: const MapOptions(
            //     initialCenter: LatLng(13.0108, 77.4862), // Bengaluru
            //     initialZoom: 12,
            //     // maxZoom: 18,
            //     // minZoom: 3,
            //     backgroundColor: Colors.transparent,
            //   ),
            //   children: [
            //     // Base Layer (MapTiler)
            //     // TileLayer(
            //     //   urlTemplate:
            //     //   'https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/tile/{z}/{y}/{x}',
            //     //   userAgentPackageName: 'com.example.app',
            //     // ),
            //     //
            //     // // KGIS Overlay (Water Bodies)
            //     // TileLayer(
            //     //   urlTemplate: 'https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/tile/{z}/{y}/{x}',
            //     //
            //     // ),
            //           TileLayer(
            //             urlTemplate:
            //                 'https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/tile/{z}/{y}/{x}',
            //             userAgentPackageName: 'com.example.app',
            //           ),
            //
            //     // Blue Dot Marker
            //     if (latitude != null && longitude != null)
            //       MarkerLayer(
            //         markers: [
            //           Marker(
            //             point: LatLng(latitude!, longitude!),
            //             width: 25,
            //             height: 25,
            //             child: Container(
            //               decoration: BoxDecoration(
            //                 color: Colors.blueAccent,
            //                 shape: BoxShape.circle,
            //                 border: Border.all(
            //                   color: Colors.white,
            //                   width: 3,
            //                 ),
            //                 boxShadow: const [
            //                   BoxShadow(
            //                     color: Colors.black26,
            //                     blurRadius: 4,
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //
            //     // Modern Scalebar (Built-in to v7)
            //     const Scalebar(
            //       alignment: Alignment.bottomLeft,
            //       lineColor: Colors.black,
            //       textStyle: TextStyle(
            //         color: Colors.black,
            //         fontSize: 12,
            //         fontWeight: FontWeight.bold,
            //       ),
            //       padding: EdgeInsets.symmetric(
            //         horizontal: 12,
            //         vertical: 20,
            //       ),
            //     ),
            //   ],
            // ),
            //     Expanded(
            //       child: FlutterMap(
            //         mapController: _mapController,
            //         options: const MapOptions(
            //           initialCenter: LatLng(13.01088494, 77.48624457),
            //           initialZoom: 12,
            //           maxZoom: 18,
            //           minZoom: 6,
            //         ),
            //         children: [
            //           // 1. Base Layer (Using OpenStreetMap - No Key Required for testing)
            //           TileLayer(
            //             urlTemplate: 'https://tile.openstreetmap.org{z}/{x}/{y}.png',
            //             userAgentPackageName: 'com.example.app',
            //           ),
            //
            //           // 2. KGIS Layer (The one you had working)
            //           TileLayer(
            //             urlTemplate: 'https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/tile/{z}/{y}/{x}',
            //             userAgentPackageName: 'com.example.app',
            //             // IMPORTANT: Use this to prevent the "disappearing" crash on 404s
            //             errorImageProvider: const NetworkImage('https://via.placeholder.com'),
            //             // Forces the layer to be transparent so OSM shows through
            //             backgroundColor: Colors.transparent,
            //           ),
            //
            //           // 3. Scalebar (Must be a child of FlutterMap)
            //           const Scalebar(
            //             alignment: Alignment.bottomLeft,
            //             lineColor: Colors.black,
            //           ),
            //         ],
            //       ),
            //     ),
            //     // Action Button
            //     Positioned(
            //       bottom: 20,
            //       right: 20,
            //       child: FloatingActionButton(
            //         backgroundColor: Colors.white,
            //         onPressed: _getCurrentLocation,
            //         child: const Icon(Icons.my_location, color: Colors.blue),
            //       ),
            //     ),
            //   ],
            // ),
            // ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: const LatLng(13.01088494, 77.48624457),
                      zoom: 12,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onTap: (tapPosition, point) {
                        _handleMapTap(point);
                      },
                    ),
                    children: [
                      // 🎨 Carto Base
                      TileLayer(
                        urlTemplate:
                            "https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.example.app',

                        // 👇 IMPORTANT
                        tileBuilder: (context, widget, tile) {
                          if (_isMapLoading) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _isMapLoading = false);
                              }
                            });
                          }
                          return widget;
                        },
                      ),

                      // 🚰 KGIS Overlay
                      TileLayer(
                        urlTemplate:
                            "https://kgis.ksrsac.in/kgismaps/rest/services/Tank/Tanks_38/MapServer/tile/{z}/{y}/{x}",
                        backgroundColor: Colors.transparent,
                        userAgentPackageName: 'com.example.app',
                      ),
                    ],
                  ),

                  // 🔄 Loader Overlay
                  if (_isMapLoading)
                    AnimatedOpacity(
                      opacity: _isMapLoading ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        color: Colors.white,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  // 🔹 Current Location Button (Top Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _goToCurrentLocation,
                      child: const Icon(Icons.my_location, color: Colors.black),
                    ),
                  ),

                  // 🔹 Scale Indicator (Bottom Left - Manual Simple Scale)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Colors.white,
                      child: const Text(
                        "Scale varies by zoom",
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 10,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.red,
                      onPressed: _resetMap,
                      child: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          height: 100,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.blueAccent,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    "Select Tank Name :",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: TextFormField(
                  cursorColor: Colors.blueAccent,
                  controller: _tankController,
                  focusNode: _tankFocusNode,
                  decoration: InputDecoration(
                    labelText: "Select Tank",
                    labelStyle: TextStyle(
                      color: selectedTank != null
                          ? Colors.green
                          : _tankFocusNode.hasFocus
                          ? Colors.blue
                          : Colors.blueAccent,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),

                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: selectedTank != null
                            ? Colors.green
                            : Colors.grey,
                        width: 1,
                      ),
                    ),

                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: selectedTank != null
                            ? Colors.green
                            : Colors.blue,
                        width: 2,
                      ),
                    ),

                    errorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),

                    focusedErrorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),

                    suffixIcon: _tankController.text.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        _tankController.clear();
                        selectedTank = null; // ✅ reset selection color
                        _filterList('');
                        setState(() {});
                      },
                    ),
                  ),

                  style: const TextStyle(fontSize: 16),

                  onChanged: (value) {
                    selectedTank = null; // ✅ remove green when editing
                    _filterList(value);
                    setState(() {});
                  },

                  onTap: () {
                    if (_tankController.text.isEmpty) {
                      _filterList('');
                    }
                  },
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
