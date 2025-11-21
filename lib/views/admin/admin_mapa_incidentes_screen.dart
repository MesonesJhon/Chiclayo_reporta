import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../viewmodels/admin_reportes_viewmodel.dart';
import '../../models/reporte_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class AdminMapaIncidentesScreen extends StatefulWidget {
  const AdminMapaIncidentesScreen({super.key});

  @override
  State<AdminMapaIncidentesScreen> createState() =>
      _AdminMapaIncidentesScreenState();
}

class _AdminMapaIncidentesScreenState extends State<AdminMapaIncidentesScreen> {
  GoogleMapController? _mapController;
  static const LatLng _chiclayoCenter = LatLng(-6.7713, -79.8409);

  Position? _currentPosition;
  ReporteModel? _selectedReporte;
  List<LatLng> _routePoints = [];
  String? _routeInfo;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // intentar obtener ubicación al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminReportesViewModel>().cargarReportes();
    });
  }

  /// Obtiene la ubicación actual y la guarda en [_currentPosition].
  /// Siempre intenta dejar algún valor (real, última conocida o Chiclayo).
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // 1. Servicios de ubicación
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Los servicios de ubicación están deshabilitados.\nActiva la ubicación del dispositivo.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 2. Permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Los permisos de ubicación fueron denegados.\nPuedes habilitarlos en Ajustes.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Los permisos de ubicación están bloqueados permanentemente.\nHabilítalos en la configuración de la app.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 3. Intentar obtener posición actual con timeout (MEDIUM)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 15));
      } on TimeoutException {
        // 4. Fallback: última ubicación conocida
        position = await Geolocator.getLastKnownPosition();
      }

      // 5. Si sigue siendo null, usar Chiclayo como fallback
      if (position == null) {
        position = Position(
          latitude: _chiclayoCenter.latitude,
          longitude: _chiclayoCenter.longitude,
          accuracy: 50,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          timestamp: DateTime.now(),
          headingAccuracy: 0,
          altitudeAccuracy: 0,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo obtener tu ubicación exacta.\nSe usará Chiclayo centro como referencia.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
      });

      debugPrint(
        'Ubicación actual: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener la ubicación: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  /// Calcula ruta desde [_currentPosition] hasta [destination].
  Future<void> _getDirections(LatLng destination) async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener tu ubicación actual'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoadingRoute = true;
      _routePoints = [];
      _routeInfo = null;
    });

    try {
      final origin = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

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
          _routePoints = points;
          _routeInfo =
              '${leg['distance']['text']} • ${leg['duration']['text']}';
        });

        _fitBounds(origin, destination);
      } else {
        throw Exception(
          'No se pudo calcular la ruta. Status: ${data['status']}',
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiempo de espera agotado al calcular la ruta'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular ruta: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Set<Marker> _buildMarkers(List<ReporteModel> reportes) {
    final markers = <Marker>{};

    // Marcador de ubicación actual
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Mi ubicación'),
        ),
      );
    }

    // Marcadores de incidentes
    for (final reporte in reportes) {
      final ubicacion = reporte.ubicacion;
      if (ubicacion?.latitud == null || ubicacion?.longitud == null) continue;

      final position = LatLng(ubicacion!.latitud!, ubicacion.longitud!);
      final markerId = MarkerId('reporte_${reporte.id}');

      BitmapDescriptor icono;
      switch (reporte.prioridad.toLowerCase()) {
        case 'alta':
          icono = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          );
          break;
        case 'media':
          icono = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          );
          break;
        case 'baja':
          icono = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
          break;
        default:
          icono = BitmapDescriptor.defaultMarker;
      }

      markers.add(
        Marker(
          markerId: markerId,
          position: position,
          icon: icono,
          infoWindow: InfoWindow(
            title: reporte.titulo,
            snippet: 'Tap para ver ruta',
          ),
          onTap: () {
            setState(() {
              _selectedReporte = reporte;
            });
            _getDirections(position);
          },
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_routePoints.isEmpty) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: Colors.blue,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }


@override
Widget build(BuildContext context) {
  final viewModel = context.watch<AdminReportesViewModel>();

  return Scaffold(
    backgroundColor: AppColors.backgroundWhite,
    floatingActionButton: _buildFloatingActionButton(),
    appBar: _buildAppBar(viewModel),
    body: _buildBody(viewModel),
  );
}

Widget _buildFloatingActionButton() {
  final hasSelection = _selectedReporte?.ubicacion != null;
  return Padding(
    padding: const EdgeInsets.only(bottom: 70.0, right: 16.0),
    child: FloatingActionButton.large(
      onPressed: hasSelection ? _onShowRoutePressed : null,
      backgroundColor:
          hasSelection ? AppColors.actionGreen : Colors.grey.shade400,
      foregroundColor: Colors.white,
      heroTag: 'show_route_fab',
      child: const Icon(
        Icons.route_rounded,
        size: 32,
      ),
      tooltip: hasSelection
          ? 'Mostrar ruta'
          : 'Selecciona un incidente para trazar ruta',
      elevation: hasSelection ? 6.0 : 0.0,
      disabledElevation: 0,
    ),
  );
}

void _onShowRoutePressed() {
  if (_selectedReporte?.ubicacion != null) {
    final u = _selectedReporte!.ubicacion!;
    _getDirections(LatLng(u.latitud!, u.longitud!));
  }
}

AppBar _buildAppBar(AdminReportesViewModel viewModel) {
  return AppBar(
    title: const Text(
      'MAPA DE INCIDENTES',
      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
    ),
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.my_location),
        onPressed: _getCurrentLocation,
        tooltip: 'Mi ubicación',
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: viewModel.cargarReportes,
        tooltip: 'Actualizar',
      ),
    ],
  );
}

Widget _buildBody(AdminReportesViewModel viewModel) {
  return Stack(
    children: [
      _buildGoogleMap(viewModel),
      if (viewModel.isLoading || _isLoadingRoute) _buildLoadingOverlay(),
      if (_routeInfo != null && _selectedReporte != null)
        _buildRouteInfoCard(),
      _buildPriorityLegend(),
    ],
  );
}

Widget _buildGoogleMap(AdminReportesViewModel viewModel) {
  return GoogleMap(
    onMapCreated: (controller) {
      _mapController = controller;
      _centerOnSelectedReport();
    },
    initialCameraPosition: CameraPosition(
      target: _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : _chiclayoCenter,
      zoom: 13,
    ),
    markers: _buildMarkers(viewModel.reportes),
    polylines: _buildPolylines(),
    myLocationEnabled: true,
    //myLocationButtonEnabled: true,
    zoomControlsEnabled: true,
    mapToolbarEnabled: false,
    onTap: _onMapTapped,
  );
}

void _centerOnSelectedReport() {
  if (_selectedReporte?.ubicacion != null) {
    final position = LatLng(
      _selectedReporte!.ubicacion!.latitud!,
      _selectedReporte!.ubicacion!.longitud!,
    );
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 15),
    );
  }
}

void _onMapTapped(LatLng position) {
  if (_selectedReporte != null) {
    setState(() {
      _selectedReporte = null;
      _routePoints = [];
      _routeInfo = null;
    });
  }
}

Widget _buildLoadingOverlay() {
  return Container(
    color: Colors.black.withAlpha(77),
    child: const Center(
      child: CircularProgressIndicator(color: Colors.white),
    ),
  );
}

Widget _buildRouteInfoCard() {
  return Positioned(
    bottom: 16,
    left: 16,
    right: 16,
    child: Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedReporte!.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRouteInfo(),
            const SizedBox(height: 8),
            Text(
              _selectedReporte!.ubicacion?.direccion ?? 'Sin dirección',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildRouteInfo() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.primaryBlue.withAlpha(26),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(
          Icons.navigation,
          color: AppColors.primaryBlue,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          _routeInfo!,
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

void _clearSelection() {
  setState(() {
    _selectedReporte = null;
    _routePoints = [];
    _routeInfo = null;
  });
}

Widget _buildPriorityLegend() {
  return Positioned(
    top: 16,
    right: 16,
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Prioridad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem('Alta', Colors.red),
            _buildLegendItem('Media', Colors.orange),
            _buildLegendItem('Baja', Colors.green),
          ],
        ),
      ),
    ),
  );
}

Widget _buildLegendItem(String label, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

// Widget _buildLegendItem(String label, Color color) {

//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 2),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }


}
