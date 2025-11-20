class ApiConstants {
  // API de Decolecta (RENIEC)
  static const String decolectaBaseUrl =
      'https://api.decolecta.com'; // .com no .pe
  static const String decolectaApiKey =
      'sk_11644.6XpuTzTEUTeRUfDYe0F6A71VdbehzbAo'; // Tu token real

  // Endpoints Decolecta
  static const String consultaDni = '/v1/reniec/dni';

  // Backend propio (Autenticación)
  static const String backendBaseUrl = 'https://jhonmm.pythonanywhere.com';

  // Endpoints del backend
  static const String authRegistro = '/api/auth/registro';
  static const String authLogin = '/api/auth/login';
  static const String authLogout = '/api/auth/logout';

  // Endpoints de reportes
  static const String reportesCrear = '/api/reportes/crear';
  static const String reportesCategorias = '/api/categorias';
  static const String reportesMisReportes = '/api/reportes/mis-reportes';
  static const String reportesEditar = '/api/reportes/editar';
  static const String reportesEliminar = '/api/reportes/delete';
}

class AppConstants {
  static const String appName = 'Reportes Ciudadanos MPCh';
  static const String municipalidadNombre =
      'Municipalidad Provincial de Chiclayo';
}

// Clase para manejar el token de autenticación
// Nota: El token se guarda automáticamente en ApiService y SharedPreferences
// Esta clase es para acceso rápido si es necesario
class TokenManager {
  // Obtener el token desde ApiService (fuente de verdad)
  static String? get token {
    // El token se maneja principalmente en ApiService
    // Para obtenerlo, usa: ApiService()._token (pero es privado)
    // Mejor usar AuthViewModel para obtener el token
    return null; // Se accede a través de AuthViewModel o ApiService
  }

  // Verificar si hay un token (a través de ApiService)
  static bool get hasToken {
    // El token se verifica mejor a través de AuthViewModel.isAuthenticated
    return false; // Se verifica a través de AuthViewModel
  }
}
