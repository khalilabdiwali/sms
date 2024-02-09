import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Polyline Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermissions();
  }

  void _checkAndRequestLocationPermissions() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      await Permission.locationWhenInUse.request();
    }
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _updateMapLocation(position);
    _addPolyLine();
  }

  void _updateMapLocation(Position position) {
    _mapController.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
  }

  void _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 8,
    );
    setState(() {
      _polylines.add(polyline);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _shareLocation() async {
    if (_currentPosition != null) {
      final String text =
          'Check out my current location: https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
      Clipboard.setData(ClipboardData(text: text)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location link copied to clipboard')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text('Google Maps & Polylines'),
          centerTitle: true,
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          initialCameraPosition: CameraPosition(
            target: _currentPosition ??
                LatLng(5.152149,
                    46.199616), // Use current location or world view as fallback
            zoom: 15,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _shareLocation,
          tooltip: 'Share Location',
          child: Icon(Icons.share),
        ),
      ),
    );
  }
}
