import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class ReportLocationMap extends StatefulWidget {
  final String reportId;
  final String reportTitle;
  final String? zone;
  final String? direccion;
  final double? latitude;
  final double? longitude;
  final double? originLatitude;
  final double? originLongitude;
  final bool enableRouting;
  final bool autoRequestRoute;
  final bool showRouteButton;
  final Color? routeButtonColor;
  final IconData? routeButtonIcon;
  final String buttonMode; // 'start_trip' or 'center_location'

  const ReportLocationMap({
    super.key,
    required this.reportId,
    required this.reportTitle,
    this.zone,
    this.direccion,
    this.latitude,
    this.longitude,
    this.originLatitude,
    this.originLongitude,
    this.enableRouting = false,
    this.autoRequestRoute = false,
    this.showRouteButton = true,
    this.routeButtonColor,
    this.routeButtonIcon,
    this.buttonMode = 'start_trip',
  });

  @override
  State<ReportLocationMap> createState() => _ReportLocationMapState();
}

class _ReportLocationMapState extends State<ReportLocationMap> {
  GoogleMapController? _mapController;
  late LatLng _reportLocation;
  LatLng? _originLocation;
  final List<LatLng> _routePoints = [];
  String? _routeInfo;
  bool _isLoadingRoute = false;

  bool get _hasValidDestination =>
      widget.latitude != null && widget.longitude != null;

  // Coordenadas aproximadas de las zonas de Chiclayo
  final Map<String, LatLng> _zoneCoordinates = {
    'Balta': const LatLng(-6.7760, -79.8440),
    'Chiclayo Centro': const LatLng(-6.7635, -79.8365),
    'Pimentel': const LatLng(-6.9175, -79.9411),
    'La Victoria': const LatLng(-6.7850, -79.8500),
    'Monsefú': const LatLng(-6.8775, -79.8700),
    'Lambayeque': const LatLng(-6.7011, -79.9061),
  };

  @override
  void initState() {
    super.initState();
    _initOriginLocation();
    if (_hasValidDestination) {
      _reportLocation = LatLng(widget.latitude!, widget.longitude!);
    } else {
      final zoneKey = widget.zone ?? '';
      _reportLocation =
          _zoneCoordinates[zoneKey] ?? const LatLng(-6.7713, -79.8409);
    }

    if (widget.enableRouting && widget.autoRequestRoute && _hasValidDestination) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _getDirections();
        }
      });
    }
  }

  Set<Marker> _getMarkers() {
    return {
      Marker(
        markerId: MarkerId('report_${widget.reportId}'),
        position: _reportLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Reporte #${widget.reportId}',
          snippet: widget.direccion != null && widget.direccion!.isNotEmpty
              ? widget.direccion!
              : (widget.zone?.isNotEmpty == true
                    ? 'Zona: ${widget.zone}'
                    : widget.reportTitle),
        ),
      ),
    };
  }

  Future<void> _initOriginLocation() async {
    try {
      if (widget.originLatitude != null && widget.originLongitude != null) {
        _originLocation = LatLng(
          widget.originLatitude!,
          widget.originLongitude!,
        );
        return;
      }

      final status = await Permission.location.request();
      if (!status.isGranted) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _originLocation = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _getDirections() async {
    if (!widget.enableRouting) return;
    if (!_hasValidDestination) {
      _showSnack('No hay destino disponible para este reporte');
      return;
    }

    if (_originLocation == null) {
      await _initOriginLocation();
      if (_originLocation == null) {
        _showSnack('No se pudo obtener tu ubicación actual');
        return;
      }
    }

    setState(() {
      _isLoadingRoute = true;
      _routePoints.clear();
      _routeInfo = null;
    });

    final origin = _originLocation!;
    final destination = LatLng(widget.latitude!, widget.longitude!);

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=driving&key=${ApiConstants.googleMapsApiKey}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final points = _decodePolyline(route['overview_polyline']['points']);

        if (!mounted) return;
        setState(() {
          _routePoints.addAll(points);
          _routeInfo = '${leg['distance']['text']} • ${leg['duration']['text']}';
        });

        _fitBounds(origin, destination);
      } else {
        final status = data['status'] as String? ?? 'UNKNOWN';
        if (status == 'ZERO_RESULTS' || status == 'NOT_FOUND') {
          _showSnack('No se encontró una ruta disponible para esta ubicación');
          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_reportLocation, 16),
          );
          return;
        }
        throw Exception('Status: $status');
      }
    } on TimeoutException {
      _showSnack('Tiempo de espera agotado al calcular la ruta');
    } catch (e) {
      _showSnack('Error al calcular la ruta: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _fitBounds(LatLng origin, LatLng destination) {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude < destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
      northeast: LatLng(
        origin.latitude > destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude > destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicación - #${widget.reportId}'),
        backgroundColor: AppColors.chiclayoOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Información del reporte
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.chiclayoOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reportTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.direccion != null &&
                          widget.direccion!.isNotEmpty)
                        Text(
                          widget.direccion!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        )
                      else if (widget.zone?.isNotEmpty == true)
                        Text(
                          'Zona: ${widget.zone}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mapa
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: _reportLocation,
                    zoom: 15,
                  ),
                  markers: _getMarkers(),
                  polylines: widget.enableRouting && _routePoints.isNotEmpty
                      ? {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: _routePoints,
                            color: AppColors.primaryBlue,
                            width: 5,
                            startCap: Cap.roundCap,
                            endCap: Cap.roundCap,
                            jointType: JointType.round,
                          ),
                        }
                      : <Polyline>{},
                  myLocationEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                ),
                if (widget.enableRouting && _isLoadingRoute)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (widget.enableRouting && _routeInfo != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.navigation, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _routeInfo!,
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _routePoints.clear();
                                  _routeInfo = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Coordenadas
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Lat: ${_reportLocation.latitude.toStringAsFixed(6)}, '
                  'Lng: ${_reportLocation.longitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.enableRouting && _hasValidDestination
          ? widget.buttonMode == 'center_location'
              ? FloatingActionButton(
                  onPressed: () async {
                    await _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_reportLocation, 16),
                    );
                  },
                  backgroundColor: AppColors.chiclayoOrange,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.center_focus_strong),
                  tooltip: 'Centrar ubicación',
                )
              : FloatingActionButton(
                  onPressed: () async {
                    if (_routePoints.isNotEmpty) {
                      final bounds = _calculateBounds(_routePoints);
                      await _mapController?.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds, 60),
                      );
                    } else {
                      await _getDirections();
                    }
                  },
                  backgroundColor: AppColors.actionGreen,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.navigation),
                  tooltip: 'Iniciar viaje',
                )
          : null,
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // En caso extremo de todos los puntos iguales, ajustamos ligeramente
    if (minLat == maxLat) {
      minLat -= 0.0001;
      maxLat += 0.0001;
    }
    if (minLng == maxLng) {
      minLng -= 0.0001;
      maxLng += 0.0001;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
