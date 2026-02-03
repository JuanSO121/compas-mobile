// lib/services/AI/local_voice_service.dart
// ✅ VERSIÓN CORREGIDA - USA MODELOS COMPARTIDOS
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';
import 'dart:async';

// ✅ IMPORTAR MODELOS COMPARTIDOS
import '../../models/shared_models.dart';
import 'local_intent_engine.dart';
import 'voice_command_classifier.dart';
import 'robot_fsm.dart';

/// Servicio de voz on-device con detección de palabra de activación (esta fue la prueba que no funciono )
/// Procesamiento 100% local, sin dependencia de internet
/// La interpretación de comandos de voz en modo offline se realiza mediante un motor de reglas optimizado
/// para vocabulario reducido, priorizando tiempos de respuesta y confiabilidad sobre modelos generativos

class LocalVoiceService {
  static final LocalVoiceService _instance = LocalVoiceService._internal();
  factory LocalVoiceService() => _instance;
  LocalVoiceService._internal();

  final Logger _logger = Logger();
  final VoiceCommandClassifier _classifier = VoiceCommandClassifier();
  final RobotFSM _fsm = RobotFSM();


  // STT on-device
  final SpeechToText _stt = SpeechToText();
  bool _sttInitialized = false;
  bool _isListening = false;

  // TTS nativo
  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;
  bool _isSpeaking = false;

  // Wake word detection (desactivado por ahora)
  bool _wakeWordActive = false;

  // Callbacks
  Function(String)? onTranscription;
  Function(String)? onPartialTranscription;
  Function()? onWakeWordDetected;
  Function()? onListeningStart;
  Function()? onListeningStop;
  Function(ObstacleAlert)? onCriticalInterrupt;

  // Control de interrupciones
  bool _allowInterruptions = true;
  DateTime? _lastInterruptTime;

  /// Inicializar servicios de voz
  Future<void> initialize() async {
    try {
      _logger.i('Inicializando servicios de voz on-device...');

      await _initializeSTT();
      await _initializeTTS();

      // ✅ NUEVO: Inicializar clasificador TFLite
      await _classifier.initialize();
      _logger.i('✅ Clasificador TFLite inicializado');

      _logger.i('✅ Servicios de voz inicializados');

    } catch (e) {
      _logger.e('❌ Error inicializando servicios de voz: $e');
      throw Exception('Fallo al inicializar servicios de voz: $e');
    }
  }

  /// Inicializar Speech-to-Text on-device
  Future<void> _initializeSTT() async {
    try {
      _sttInitialized = await _stt.initialize(
        onError: (error) => _logger.e('STT Error: ${error.errorMsg}'),
        onStatus: (status) => _logger.d('STT Status: $status'),
        debugLogging: false,
      );

      if (!_sttInitialized) {
        throw Exception('STT no disponible en este dispositivo');
      }

      _logger.i('✅ Reconocimiento de voz inicializado');
      _logger.w('⚠️ El tipo de reconocimiento (on-device/cloud) depende del SO');

    } catch (e) {
      _logger.e('Error inicializando STT: $e');
      rethrow;
    }
  }

  /// Inicializar Text-to-Speech
  Future<void> _initializeTTS() async {
    try {
      _tts.setStartHandler(() {
        _isSpeaking = true;
        _logger.d('TTS iniciado');
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _logger.d('TTS completado');
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _logger.e('TTS Error: $msg');
      });

      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // ✅ FIX: Manejar tipos dinámicos correctamente
      try {
        final voices = await _tts.getVoices;
        if (voices != null && voices is List && voices.isNotEmpty) {
          final spanishVoices = voices.where((voice) {
            // Manejar voz como Map dinámico
            if (voice is Map) {
              final locale = voice['locale'];
              return locale != null && locale.toString().startsWith('es');
            }
            return false;
          }).toList();

          if (spanishVoices.isNotEmpty) {
            await _tts.setVoice(spanishVoices.first as Map<String, String>);
            _logger.i('Voz española configurada');
          }
        }
      } catch (e) {
        // Si falla la configuración de voz específica, continuar con voz por defecto
        _logger.w('No se pudo configurar voz específica, usando por defecto: $e');
      }

      _ttsInitialized = true;

    } catch (e) {
      _logger.e('Error inicializando TTS: $e');
      rethrow;
    }
  }

  /// Iniciar escucha continua con chunks
  Future<void> startListening({
    String localeId = 'es-ES',
  }) async {
    if (!_sttInitialized) {
      throw Exception('STT no inicializado');
    }

    if (_isListening) {
      _logger.w('Ya está escuchando');
      return;
    }

    try {
      await _stt.listen(
        onResult: (result) {
          if (result.finalResult) {
            _handleFinalTranscription(result.recognizedWords);
          } else {
            _handlePartialTranscription(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenMode: ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
        onSoundLevelChange: (level) {
          // Opcionalmente mostrar nivel de audio
        },
      );

      _isListening = true;
      onListeningStart?.call();
      _logger.i('🎤 Escucha iniciada');

    } catch (e) {
      _logger.e('Error iniciando escucha: $e');
      rethrow;
    }
  }

  /// Detener escucha
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _stt.stop();
      _isListening = false;
      _wakeWordActive = false;
      onListeningStop?.call();
      _logger.i('🎤 Escucha detenida');

    } catch (e) {
      _logger.e('Error deteniendo escucha: $e');
    }
  }

  /// Manejar transcripción parcial (chunks)
  void _handlePartialTranscription(String partial) {
    if (partial.isEmpty) return;

    _logger.v('Partial: $partial');
    onPartialTranscription?.call(partial);
  }

  /// Manejar transcripción final
  Future<void> _handleFinalTranscription(String text) async {
    if (text.isEmpty) return;

    _logger.i('Transcripción: $text');

    try {
      // 1. Clasificar con TFLite
      final result = await _classifier.classify(text);

      if (result.hasError) {
        _logger.e('Error en clasificación: ${result.errorMessage}');
        return;
      }

      _logger.i('   → ${result.label} (${(result.confidence * 100).toStringAsFixed(1)}%)');

      // 2. Validar chunk
      if (!_classifier.validateChunk(text, result.label)) {
        _logger.w('   ❌ Chunk rechazado');
        return;
      }

      // 3. Verificar threshold
      if (!result.passesThreshold) {
        _logger.w('   ❌ Confianza insuficiente');
        await speak('No entendí bien el comando');
        return;
      }

      // 4. Validar con FSM
      final action = _labelToAction(result.label);
      final (canExec, reason) = _fsm.canExecute(action, result.confidence);

      if (!canExec) {
        _logger.w('   ⛔ FSM rechazó: $reason');
        await speak(reason);
        return;
      }

      // 5. Ejecutar
      final executed = _fsm.execute(action, result.confidence, text);

      if (executed) {
        _logger.i('   ✅ Comando ejecutado: ${result.label}');

        // Llamar callback original
        onTranscription?.call(text);

        // Respuesta de voz
        await speak(_getConfirmationMessage(result.label));
      }

    } catch (e) {
      _logger.e('Error procesando transcripción: $e');
    }
  }

  // ✅ HELPER: Mapear label a Action
  Action _labelToAction(String label) {
    switch (label) {
      case 'MOVE': return Action.move;
      case 'STOP': return Action.stop;
      case 'TURN_LEFT': return Action.turnLeft;
      case 'TURN_RIGHT': return Action.turnRight;
      case 'REPEAT': return Action.repeat;
      case 'HELP': return Action.help;
      default: return Action.unknown;
    }
  }

  // ✅ HELPER: Mensaje de confirmación
  String _getConfirmationMessage(String label) {
    switch (label) {
      case 'MOVE': return 'Avanzando';
      case 'STOP': return 'Detenido';
      case 'TURN_LEFT': return 'Girando a la izquierda';
      case 'TURN_RIGHT': return 'Girando a la derecha';
      case 'HELP': return '¿En qué puedo ayudarte?';
      case 'REPEAT': return 'Repitiendo última acción';
      default: return 'Comando no reconocido';
    }
  }

  /// Hablar con prioridad e interrupción
  Future<void> speak(
      String text, {
        bool priority = false,
        bool allowInterrupt = true,
      }) async {
    if (!_ttsInitialized) {
      throw Exception('TTS no inicializado');
    }

    if (text.trim().isEmpty) return;

    if (_isSpeaking && priority) {
      await stopSpeaking();
      await Future.delayed(Duration(milliseconds: 100));
    }

    if (_isSpeaking && !priority) {
      _logger.w('TTS ocupado, mensaje descartado');
      return;
    }

    try {
      _allowInterruptions = allowInterrupt;

      final cleanText = _cleanTextForTTS(text);
      await _tts.speak(cleanText);

      _logger.i('🔊 TTS: $cleanText');

    } catch (e) {
      _logger.e('Error en TTS: $e');
      _isSpeaking = false;
    }
  }

  /// Detener TTS inmediatamente
  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;

    try {
      await _tts.stop();
      _isSpeaking = false;
      _logger.d('TTS interrumpido');

    } catch (e) {
      _logger.e('Error deteniendo TTS: $e');
    }
  }

  /// Manejar interrupción crítica (obstáculo)
  Future<void> handleCriticalInterrupt(ObstacleAlert alert) async {
    if (_lastInterruptTime != null &&
        DateTime.now().difference(_lastInterruptTime!).inSeconds < 1) {
      return;
    }

    _lastInterruptTime = DateTime.now();

    if (_isSpeaking) {
      await stopSpeaking();
    }

    final urgentMessage = _buildUrgentMessage(alert);

    await speak(
      urgentMessage,
      priority: true,
      allowInterrupt: false,
    );

    onCriticalInterrupt?.call(alert);
  }

  /// Construir mensaje urgente
  String _buildUrgentMessage(ObstacleAlert alert) {
    switch (alert.riskLevel) {
      case RiskLevel.critical:
        return '¡ALTO! Obstáculo a ${alert.distance.toStringAsFixed(0)} metros ${alert.direction}. ${alert.recommendedAction}';
      case RiskLevel.high:
        return 'Cuidado, obstáculo cercano ${alert.direction}';
      case RiskLevel.medium:
        return 'Precaución, objeto detectado ${alert.direction}';
      default:
        return 'Atención';
    }
  }

  /// Limpiar texto para TTS
  String _cleanTextForTTS(String text) {
    return text
        .replaceAll(RegExp(r'ROS\s*2?'), 'ros')
        .replaceAll(RegExp(r'AI|IA'), 'inteligencia artificial')
        .replaceAll(RegExp(r'AR'), 'realidad aumentada')
        .replaceAll(RegExp(r'NPU'), 'unidad de procesamiento neural')
        .replaceAll(RegExp(r'[^\w\s\.,!?;:()\-áéíóúñÁÉÍÓÚÑ]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Activar/desactivar wake word (placeholder)
  Future<void> setWakeWordEnabled(bool enabled) async {
    _logger.d('Wake word no disponible (requiere Porcupine configurado)');
  }

  /// Configurar velocidad de voz
  Future<void> setSpeechRate(double rate) async {
    if (!_ttsInitialized) return;

    try {
      await _tts.setSpeechRate(rate.clamp(0.3, 1.0));
      _logger.d('Velocidad de voz: $rate');
    } catch (e) {
      _logger.e('Error configurando velocidad: $e');
    }
  }

  /// Configurar volumen
  Future<void> setVolume(double volume) async {
    if (!_ttsInitialized) return;

    try {
      await _tts.setVolume(volume.clamp(0.0, 1.0));
      _logger.d('Volumen: $volume');
    } catch (e) {
      _logger.e('Error configurando volumen: $e');
    }
  }

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _sttInitialized && _ttsInitialized;
  bool get wakeWordActive => _wakeWordActive;

  void dispose() {
    if (_isListening) {
      _stt.stop();
    }
    if (_isSpeaking) {
      _tts.stop();
    }
    _classifier.dispose();  // ✅ NUEVO
    _logger.i('LocalVoiceService disposed');
  }
}