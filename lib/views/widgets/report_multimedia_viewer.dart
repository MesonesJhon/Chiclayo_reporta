import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/reporte_model.dart';
import '../../models/archivo_multimedia_model.dart';
import '../../utils/app_colors.dart';

class ReportMultimediaViewer extends StatefulWidget {
  final ReporteModel reporte;

  const ReportMultimediaViewer({super.key, required this.reporte});

  @override
  State<ReportMultimediaViewer> createState() => _ReportMultimediaViewerState();
}

class _ReportMultimediaViewerState extends State<ReportMultimediaViewer> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, Future<void>> _videoInitFutures = {};

  List<ArchivoMultimediaModel> get _archivos => widget.reporte.archivos;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isVideo(ArchivoMultimediaModel archivo) {
    final type = archivo.mimeType ?? archivo.tipo;
    return type.toLowerCase().contains('video');
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            height: 5,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Archivos - #${widget.reporte.id ?? widget.reporte.codigoSeguimiento}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${_archivos.length} ${_archivos.length == 1 ? 'archivo' : 'archivos'}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _archivos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final archivo = _archivos[index];
                return _buildMediaItem(archivo, index);
              },
            ),
          ),
          const SizedBox(height: 16),
          // Indicadores de página
          if (_archivos.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _archivos.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMediaItem(ArchivoMultimediaModel archivo, int index) {
    if (_isVideo(archivo)) {
      return _buildVideoPlayer(archivo, index);
    } else {
      return InteractiveViewer(
        child: Image.network(
          archivo.url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Error al cargar la imagen'),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildVideoPlayer(ArchivoMultimediaModel archivo, int index) {
    // Inicializar controlador si no existe
    if (!_videoControllers.containsKey(index)) {
      _videoControllers[index] = VideoPlayerController.networkUrl(
        Uri.parse(archivo.url),
      );
      _videoInitFutures[index] = _videoControllers[index]!.initialize();
    }

    final controller = _videoControllers[index]!;

    return FutureBuilder(
      future: _videoInitFutures[index],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              // Controles básicos
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    });
                  },
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
