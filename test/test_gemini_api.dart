// test/test_gemini_api.dart
// Script para debuggear exactamente qué pasa con gemini, probando varios modelos.

import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

// ✅ Lista de modelos a probar, en orden de prioridad.
// 1. 'gemini-pro': El más estable y con mejor cuota gratuita.
// 2. 'gemini-1.5-flash-latest': El que parece funcionar en tu consola, pero con baja cuota.
const modelsToTest = [
  'gemini-flash-latest'
];

// Variable global para almacenar el modelo que funcione
String? _workingModelName;

void main() async {
  // ✅ Tu API key aquí. ¡CUIDADO! NO SUBAS ESTA KEY A REPOSITORIOS PÚBLICOS.
  const apiKey = 'AIzaSyCaIxaNdYqMbvnVrXqT4EDdKgNyVjXkWIs'; // Reemplaza con tu key real

  print('🔍 TEST GEMINI API - DEBUGGING');
  print('=' * 60);

  try {
    await testBasicConnection(apiKey);
    await testSimpleRequest(apiKey);
    await testJsonRequest(apiKey);
    await testVoiceCommand(apiKey);
  } catch (e) {
    print('\n❌ Error general no capturado en los tests: $e');
  }

  print('\n✅ Tests completados');
  if (_workingModelName != null) {
    print('\n🎉 ¡El modelo funcional es: "$_workingModelName"!');
    print('--> Usa este nombre en el código de tu aplicación principal.');
  } else {
    print('\n\n⚠️ No se encontró ningún modelo funcional para esta API Key.');
    print('Verifica que la API Key sea correcta y que la API "Generative Language" esté habilitada en tu proyecto de Google Cloud.');
  }
}

/// Función genérica para encontrar un modelo que funcione y ejecutar un test.
Future<void> _runTest(
  String testName,
  String apiKey,
  Future<void> Function(GenerativeModel model) testLogic,
) async {
  print('\n📋 TEST: $testName');

  // Si ya encontramos un modelo, lo usamos directamente.
  if (_workingModelName != null) {
    print('   ▶️ Usando el modelo funcional ya conocido: "$_workingModelName"');
    try {
      final model = GenerativeModel(model: _workingModelName!, apiKey: apiKey);
      await testLogic(model);
      print('   ✅ Éxito.');
      return;
    } catch (e) {
      print('   - ❌ Falló incluso con el modelo conocido: ${e.toString().split('\n').first}');
      _workingModelName = null; // Resetear para que la siguiente prueba busque de nuevo.
      return;
    }
  }

  // Si no conocemos un modelo funcional, lo buscamos en la lista.
  for (final modelName in modelsToTest) {
    print('   ▶️ Intentando con el modelo: "$modelName"');
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      await testLogic(model);
      
      print('   ✅ Éxito con el modelo: "$modelName"');
      _workingModelName = modelName; // Guardamos el nombre del modelo que funcionó.
      return; // Salimos al encontrar uno que funcione.
    } catch (e) {
      print('   - ❌ Falló para "$modelName": ${e.toString().split('\n').first}');
    }
  }
  print('   ❌ Todos los modelos fallaron para este test.');
}

// --- Definiciones de los tests ---

Future<void> testBasicConnection(String apiKey) async {
  await _runTest('Conexión básica', apiKey, (model) async {
    final response = await model
        .generateContent([Content.text('Responde solo con: OK')])
        .timeout(const Duration(seconds: 5));

    if (response.text?.trim() != 'OK') {
      throw Exception('La respuesta no fue "OK", fue: "${response.text}"');
    }
    print('   - Respuesta recibida: "${response.text?.trim()}"');
  });
}

Future<void> testSimpleRequest(String apiKey) async {
  await _runTest('Request simple (Hola)', apiKey, (model) async {
    final response = await model
        .generateContent([Content.text('Hola, ¿cómo estás?')])
        .timeout(const Duration(seconds: 5));

    if (response.text == null || response.text!.isEmpty) {
      throw Exception('Respuesta vacía o nula.');
    }
    print('   - Respuesta: "${response.text?.trim()}"');
  });
}

Future<void> testJsonRequest(String apiKey) async {
  final prompt = '''Clasifica el siguiente texto: "avanza". Responde SOLO con JSON: {"label": "MOVE", "confidence": 0.95}''';
  await _runTest('Request esperando JSON', apiKey, (model) async {
    final response = await model
        .generateContent([Content.text(prompt)])
        .timeout(const Duration(seconds: 5));

    if (response.text == null) throw Exception('Respuesta nula');
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response.text!);
    if (jsonMatch == null) throw Exception('No se encontró JSON en: "${response.text}"');
    
    final jsonText = jsonMatch.group(0)!;
    jsonDecode(jsonText); // Intenta parsear para validar.
    print('   - JSON recibido: $jsonText');
  });
}

Future<void> testVoiceCommand(String apiKey) async {
  final command = 'gira a la izquierda';
  final prompt = '''Clasifica el comando "$command" en una de estas categorías: MOVE, STOP, TURN_LEFT, TURN_RIGHT. Responde SOLO con JSON: {"label": "CATEGORIA", "confidence": 0.XX}''';
  await _runTest('Comando de voz real', apiKey, (model) async {
    final response = await model
        .generateContent([Content.text(prompt)])
        .timeout(const Duration(seconds: 5));

    if (response.text == null) throw Exception('Respuesta nula');
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response.text!);
    if (jsonMatch == null) throw Exception('No se encontró JSON en: "${response.text}"');
    
    print('   - JSON recibido para "$command": ${jsonMatch.group(0)!}');
  });
}

// Helper (ya no es necesario pero se deja por si acaso)
extension FirstOrNull<T> on List<T> {
  T? firstOrNull() => isEmpty ? null : first;
}
