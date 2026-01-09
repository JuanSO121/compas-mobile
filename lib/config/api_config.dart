// lib/config/api_config.dart
class ApiConfig {
  // IMPORTANTE: Cambia esta URL por la IP de tu servidor
  // Para desarrollo local:
  // - Android Emulator: 'http://10.0.2.2:8000'
  // - iOS Simulator: 'http://localhost:8000'
  // - Dispositivo físico: 'http://TU_IP_LOCAL:8000'
  static const String baseUrlPC = 'http://127.0.0.1:8080';
  static const String baseUrl = 'http://192.168.1.6:8080';


  // Endpoints
  static const String apiVersion = '/api/v1';

  // Auth endpoints
  static const String register = '$apiVersion/auth/register';
  static const String login = '$apiVersion/auth/login';
  static const String logout = '$apiVersion/auth/logout';
  static const String refreshToken = '$apiVersion/auth/refresh';
  static const String forgotPassword = '$apiVersion/auth/forgot-password';
  static const String resetPassword = '$apiVersion/auth/reset-password';
  static const String verifyEmail = '$apiVersion/auth/verify-email';

  // User endpoints
  static const String userProfile = '$apiVersion/users/profile';
  static const String updateProfile = '$apiVersion/users/profile';
  static const String deleteAccount = '$apiVersion/users/account';
  static const String activityLog = '$apiVersion/users/activity-log';

  // Accessibility endpoints
  static const String updateAccessibility = '$apiVersion/accessibility/preferences';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}