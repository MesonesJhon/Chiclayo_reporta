import 'dart:async'; // Para TimeoutException
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/app_colors.dart';

class SeleccionarUbicacionMap extends StatefulWidget {
  final double? latitudInicial;
  final double? longitudInicial;
  final String? direccionInicial;
  final String? distritoInicial;

  const SeleccionarUbicacionMap({
    super.key,
    this.latitudInicial,
    this.longitudInicial,
    this.direccionInicial,
    this.distritoInicial,
  });

  @override
  State<SeleccionarUbicacionMap> createState() =>
      _SeleccionarUbicacionMapState();
}

class _SeleccionarUbicacionMapState extends State<SeleccionarUbicacionMap> {
  static const double _defaultLat = -6.7713; // Chiclayo
  static const double _defaultLng = -79.8409;
  static const double _defaultZoom = 17;

  double? _latitud;
  double? _longitud;
  String? _direccion;
  String? _distrito;
  bool _isLoading = false;
  String _errorMessage = '';

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _latitud = widget.latitudInicial;
    _longitud = widget.longitudInicial;
    _direccion = widget.direccionInicial;
    _distrito = widget.distritoInicial;

    // Obtener ubicación automáticamente si no hay inicial
    if (_latitud == null || _longitud == null) {
      _obtenerUbicacionActual();
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Verificar si los servicios de ubicación están habilitados
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Los servicios de ubicación están deshabilitados.\n'
              'Activa la ubicación del dispositivo o selecciona la ubicación manualmente.';
        });
        return;
      }

      // 2. Verificar permisos
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _errorMessage =
                'Los permisos de ubicación fueron denegados.\n'
                'Puedes habilitarlos en Ajustes o elegir la ubicación manualmente.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Los permisos de ubicación están bloqueados permanentemente.\n'
              'Habilítalos en la configuración de la app o usa la selección manual.';
        });
        return;
      }

      // 3. Obtener ubicación actual con límite de tiempo
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _direccion = _direccion ?? 'Ubicación actual';
        _distrito = _distrito ?? 'Chiclayo';
        _errorMessage = '';
      });

      _moverCamaraALocacion();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'No se pudo obtener tu ubicación a tiempo.\n'
            'Puedes seleccionar la ubicación manualmente.';
        // Fallback: Plaza de Armas de Chiclayo
        _latitud ??= _defaultLat;
        _longitud ??= _defaultLng;
        _direccion ??= 'Plaza de Armas de Chiclayo';
        _distrito ??= 'Chiclayo';
      });
      _moverCamaraALocacion();
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Ocurrió un problema al obtener la ubicación.\n'
            'Puedes seleccionar la ubicación manualmente.';
        _latitud ??= _defaultLat;
        _longitud ??= _defaultLng;
        _direccion ??= 'Plaza de Armas de Chiclayo';
        _distrito ??= 'Chiclayo';
      });
      _moverCamaraALocacion();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _seleccionarUbicacionManual() {
    if (!mounted) return;

    setState(() {
      _latitud = _defaultLat;
      _longitud = _defaultLng;
      _direccion = 'Plaza de Armas de Chiclayo';
      _distrito = 'Chiclayo';
      _errorMessage = '';
    });
    _moverCamaraALocacion();
  }

  void _moverCamaraALocacion() {
    if (_mapController != null && _latitud != null && _longitud != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_latitud!, _longitud!),
            zoom: _defaultZoom,
          ),
        ),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    if (_latitud == null || _longitud == null) return {};

    return {
      Marker(
        markerId: const MarkerId('ubicacion_seleccionada'),
        position: LatLng(_latitud!, _longitud!),
        draggable: true,
        onDragEnd: (pos) {
          setState(() {
            _latitud = pos.latitude;
            _longitud = pos.longitude;
          });
        },
      ),
    };
  }

  Set<Circle> _buildCircles() {
    if (_latitud == null || _longitud == null) return {};

    return {
      Circle(
        circleId: const CircleId('radio'),
        center: LatLng(_latitud!, _longitud!),
        radius: 50, // metros (20–50 m aprox., puedes ajustar)
        fillColor: AppColors.primaryBlue.withOpacity(0.1),
        strokeColor: AppColors.primaryBlue.withOpacity(0.5),
        strokeWidth: 1,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final initialLat = _latitud ?? _defaultLat;
    final initialLng = _longitud ?? _defaultLng;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información de ubicación
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        const Text(
                          'Ubicación Seleccionada',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_latitud != null && _longitud != null) ...[
                      Text(
                        'Latitud: ${_latitud!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Longitud: ${_longitud!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_direccion != null && _direccion!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Dirección: $_direccion',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      if (_distrito != null && _distrito!.isNotEmpty) ...[
                        Text(
                          'Distrito: $_distrito',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'No se ha seleccionado ubicación',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mensaje de error (si lo hay)
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.criticalRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.criticalRed),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: AppColors.criticalRed),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Map + botones
            Expanded(
              child: Column(
                children: [
                  // Botones de acción
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _obtenerUbicacionActual,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Mi Ubicación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _seleccionarUbicacionManual,
                            icon: const Icon(Icons.location_searching),
                            label: const Text('Chiclayo Centro'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Google Map
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(initialLat, initialLng),
                          zoom: _defaultZoom,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          // Cuando ya se crea el mapa, centramos si ya hay ubicación
                          _moverCamaraALocacion();
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        markers: _buildMarkers(),
                        circles: _buildCircles(),
                        onTap: (LatLng pos) {
                          setState(() {
                            _latitud = pos.latitude;
                            _longitud = pos.longitude;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
      floatingActionButton: (_latitud != null && _longitud != null)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, {
                  'latitud': _latitud!,
                  'longitud': _longitud!,
                  'direccion': _direccion,
                  'distrito': _distrito,
                });
              },
              backgroundColor: AppColors.actionGreen,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar Ubicación'),
            )
          : null,
    );
  }
}
