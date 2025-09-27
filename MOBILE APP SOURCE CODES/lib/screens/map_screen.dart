import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final LatLng soilLocation;
  final List<LatLng>? polygonPoints;

  const MapScreen({
    super.key,
    required this.soilLocation,
    this.polygonPoints,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  double _currentZoom = 14.0;
  late LatLng _currentCenter;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.soilLocation;
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Check for location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_currentCenter, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_currentCenter, _currentZoom);
    });
  }

  void _goToUserLocation() {
    if (_userLocation != null) {
      setState(() {
        _currentCenter = _userLocation!;
        _currentZoom = 16;
        _mapController.move(_currentCenter, _currentZoom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Planting Area Map"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.soilLocation,
              initialZoom: _currentZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (position, _) {
                _currentCenter = position.center;
                _currentZoom = position.zoom;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (widget.polygonPoints != null &&
                  widget.polygonPoints!.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: widget.polygonPoints!,
                      color: Colors.green.withOpacity(0.3),
                      borderColor: Colors.green.shade800,
                      borderStrokeWidth: 3.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Planting point marker
                  Marker(
                    point: widget.soilLocation,
                    width: 80,
                    height: 80,
                    child:
                        const Icon(Icons.place, color: Colors.red, size: 40),
                  ),
                  // User location marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.person_pin_circle,
                          color: Colors.blue, size: 35),
                    ),
                ],
              ),
            ],
          ),

          // Zoom Controls
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoomIn',
                  onPressed: _zoomIn,
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoomOut',
                  onPressed: _zoomOut,
                  child: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),

          // User Location Button
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'userLocation',
              onPressed: _goToUserLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Legend Card
          Positioned(
            bottom: 20,
            right: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("🟢 Green area: Planting zone",
                        style: TextStyle(fontSize: 14)),
                    SizedBox(height: 6),
                    Text("🔴 Red marker: Planting point",
                        style: TextStyle(fontSize: 14)),
                    SizedBox(height: 6),
                    Text("🔵 Blue dot: Your location",
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
