// widgets/report_location_map.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/app_colors.dart';

class ReportLocationMap extends StatefulWidget {
  final String reportId;
  final String reportTitle;
  final String? zone;
  final String? direccion;
  final double? latitude;
  final double? longitude;

  const ReportLocationMap({
    super.key,
    required this.reportId,
    required this.reportTitle,
    this.zone,
    this.direccion,
    this.latitude,
    this.longitude,
  });

  @override
  State<ReportLocationMap> createState() => _ReportLocationMapState();
}

class _ReportLocationMapState extends State<ReportLocationMap> {
  late GoogleMapController _mapController;
  late LatLng _reportLocation;

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
    if (widget.latitude != null && widget.longitude != null) {
      _reportLocation = LatLng(widget.latitude!, widget.longitude!);
    } else {
      final zoneKey = widget.zone ?? '';
      _reportLocation =
          _zoneCoordinates[zoneKey] ??
          const LatLng(-6.7713, -79.8409); // Chiclayo por defecto
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
            child: GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _reportLocation,
                zoom: 15,
              ),
              markers: _getMarkers(),
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: true,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(_reportLocation, 16),
          );
        },
        backgroundColor: AppColors.chiclayoOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.center_focus_strong_rounded),
        tooltip: 'Centrar en ubicación',
      ),
    );
  }
}
