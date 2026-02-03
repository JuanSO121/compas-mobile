// lib/services/AI/local_intent_engine.dart
import '../../models/shared_models.dart';

class LocalIntentEngine {

  static NavigationIntent analyze(String text) {
    final command = text.toLowerCase();

    // ⛔ STOP
    if (_containsAny(command, ['para', 'detente', 'alto', 'espera'])) {
      return NavigationIntent(
        type: IntentType.stop,
        priority: 100,
        target: '',
        suggestedResponse: 'Deteniéndome',
      );
    }

    // 🧭 NAVIGATE
    if (_containsAny(command, ['llévame', 'ir a', 'quiero ir', 'guíame'])) {
      final target = _extractTarget(command);
      return NavigationIntent(
        type: IntentType.navigate,
        priority: 8,
        target: target,
        suggestedResponse: 'Iniciando navegación hacia $target',
      );
    }

    // 👀 DESCRIBE
    if (_containsAny(command, ['qué hay', 'descríbeme', 'dónde estoy'])) {
      return NavigationIntent(
        type: IntentType.describe,
        priority: 5,
        target: '',
        suggestedResponse: 'Analizando entorno',
      );
    }

    // 🚧 OBSTACLE
    if (_containsAny(command, ['hay algo', 'puedo pasar', 'obstáculo'])) {
      return NavigationIntent(
        type: IntentType.obstacle,
        priority: 9,
        target: '',
        suggestedResponse: 'Verificando obstáculos',
      );
    }

    // ❓ UNKNOWN
    return NavigationIntent.unknown();
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  static String _extractTarget(String text) {
    const places = ['baño', 'salida', 'escaleras', 'puerta'];
    return places.firstWhere(
          (p) => text.contains(p),
      orElse: () => 'destino',
    );
  }
}
