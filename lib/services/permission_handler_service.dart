// lib/services/permission_handler_service.dart
// ✅ MANEJO CENTRALIZADO DE PERMISOS

import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

/// Servicio centralizado para gestionar permisos de la app
class PermissionHandlerService {
  static final PermissionHandlerService _instance =
  PermissionHandlerService._internal();
  factory PermissionHandlerService() => _instance;
  PermissionHandlerService._internal();

  final Logger _logger = Logger();

  /// Verificar y solicitar todos los permisos necesarios
  Future<PermissionStatus> ensureAllPermissions() async {
    _logger.i('Verificando permisos...');

    // Verificar estado actual
    final micStatus = await Permission.microphone.status;
    final cameraStatus = await Permission.camera.status;

    _logger.d('Micrófono: $micStatus');
    _logger.d('Cámara: $cameraStatus');

    // Solicitar permisos faltantes
    if (micStatus.isDenied) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        _logger.e('Permiso de micrófono denegado');
        return result;
      }
    }

    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        _logger.e('Permiso de cámara denegado');
        return result;
      }
    }

    // Verificar permisos permanentemente denegados
    if (await Permission.microphone.isPermanentlyDenied) {
      _logger.e('Permiso de micrófono permanentemente denegado');
      throw PermissionPermanentlyDeniedException(
        'Micrófono',
        'Por favor habilita el permiso de micrófono en Configuración',
      );
    }

    if (await Permission.camera.isPermanentlyDenied) {
      _logger.e('Permiso de cámara permanentemente denegado');
      throw PermissionPermanentlyDeniedException(
        'Cámara',
        'Por favor habilita el permiso de cámara en Configuración',
      );
    }

    _logger.i('✅ Todos los permisos concedidos');
    return PermissionStatus.granted;
  }

  /// Verificar solo micrófono
  Future<bool> ensureMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      throw PermissionPermanentlyDeniedException(
        'Micrófono',
        'Permiso permanentemente denegado',
      );
    }

    return false;
  }

  /// Verificar solo cámara
  Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      throw PermissionPermanentlyDeniedException(
        'Cámara',
        'Permiso permanentemente denegado',
      );
    }

    return false;
  }

  /// Abrir configuración de la app
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Verificar si todos los permisos están concedidos
  Future<bool> hasAllPermissions() async {
    final micGranted = await Permission.microphone.isGranted;
    final cameraGranted = await Permission.camera.isGranted;

    return micGranted && cameraGranted;
  }
}

/// Excepción personalizada para permisos permanentemente denegados
class PermissionPermanentlyDeniedException implements Exception {
  final String permission;
  final String message;

  PermissionPermanentlyDeniedException(this.permission, this.message);

  @override
  String toString() => 'PermissionPermanentlyDeniedException: $permission - $message';
}