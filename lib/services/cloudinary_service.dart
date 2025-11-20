import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class CloudinaryService {
  static const String _cloudName = 'ds5pdejzu';
  static const String _apiKey = '933528755234865';
  static const String _apiSecret = 'NxlkaWbk59R_OXpdeTQAXUaNu9E';

  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  Future<CloudinaryUploadResult> uploadFile(
    File file, {
    String folder = 'reportes',
  }) async {
    if (!await file.exists()) {
      throw Exception('El archivo no existe en la ruta ${file.path}');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload',
    );
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final paramsToSign = {'folder': folder, 'timestamp': timestamp};

    final signature = _generateSignature(paramsToSign);

    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = _apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final rawResponse = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode >= 200 &&
        streamedResponse.statusCode < 300) {
      final data = json.decode(rawResponse) as Map<String, dynamic>;
      return CloudinaryUploadResult.fromJson(
        data,
        file,
        lookupMimeType(file.path) ?? 'application/octet-stream',
      );
    } else {
      throw Exception(
        'Error subiendo archivo a Cloudinary (${streamedResponse.statusCode}): $rawResponse',
      );
    }
  }

  Future<void> deleteAssetByUrl(
    String url, {
    String resourceType = 'image',
  }) async {
    final publicId = extractPublicIdFromUrl(url);
    if (publicId == null || publicId.isEmpty) {
      throw Exception('No se pudo extraer el public_id del recurso');
    }
    await deleteAsset(publicId, resourceType: resourceType);
  }

  Future<void> deleteAsset(
    String publicId, {
    String resourceType = 'image',
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/destroy',
    );
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final paramsToSign = {'public_id': publicId, 'timestamp': timestamp};

    final signature = _generateSignature(paramsToSign);

    final response = await http.post(
      uri,
      body: {
        'public_id': publicId,
        'timestamp': timestamp,
        'api_key': _apiKey,
        'signature': signature,
      },
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'Error eliminando archivo de Cloudinary (${response.statusCode}): ${response.body}',
      );
    }
  }

  String? extractPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = List<String>.from(uri.pathSegments);
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 1 >= segments.length) {
        return null;
      }
      final publicIdSegments = segments.sublist(uploadIndex + 1);
      if (publicIdSegments.isEmpty) return null;
      // Remover versión (v123456)
      if (publicIdSegments.first.startsWith('v') &&
          int.tryParse(publicIdSegments.first.substring(1)) != null) {
        publicIdSegments.removeAt(0);
      }
      if (publicIdSegments.isEmpty) return null;
      final lastSegment = publicIdSegments.last;
      final dotIndex = lastSegment.lastIndexOf('.');
      publicIdSegments[publicIdSegments.length - 1] = dotIndex == -1
          ? lastSegment
          : lastSegment.substring(0, dotIndex);
      return publicIdSegments.join('/');
    } catch (_) {
      return null;
    }
  }

  String _generateSignature(Map<String, String> params) {
    final sortedEntries = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final signatureBase =
        '${sortedEntries.map((e) => '${e.key}=${e.value}').join('&')}$_apiSecret';
    final bytes = utf8.encode(signatureBase);
    return sha1.convert(bytes).toString();
  }
}

class CloudinaryUploadResult {
  final String publicId;
  final String secureUrl;
  final String resourceType;
  final String format;
  final String originalFilename;
  final int bytes;
  final String mimeType;

  CloudinaryUploadResult({
    required this.publicId,
    required this.secureUrl,
    required this.resourceType,
    required this.format,
    required this.originalFilename,
    required this.bytes,
    required this.mimeType,
  });

  factory CloudinaryUploadResult.fromJson(
    Map<String, dynamic> json,
    File file,
    String mimeType,
  ) {
    return CloudinaryUploadResult(
      publicId: json['public_id'] as String? ?? '',
      secureUrl: json['secure_url'] as String? ?? '',
      resourceType: json['resource_type'] as String? ?? 'image',
      format: json['format'] as String? ?? '',
      originalFilename:
          json['original_filename'] as String? ?? file.uri.pathSegments.last,
      bytes: json['bytes'] as int? ?? file.lengthSync(),
      mimeType: mimeType,
    );
  }

  bool get isVideo => resourceType.toLowerCase() == 'video';

  Map<String, dynamic> toMultimediaPayload({required bool esPrincipal}) {
    return {
      'tipo': isVideo ? 'video' : 'foto',
      'nombre_archivo': originalFilename,
      'ruta_almacenamiento': secureUrl,
      'mime_type': mimeType,
      'tamano': bytes,
      'es_principal': esPrincipal,
    };
  }
}
