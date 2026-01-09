// lib/main.dart - APLICACIÓN DE RECONOCIMIENTO ACCESIBLE (SIN ROBOT)
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'services/audio_service.dart';
import 'services/tts_service.dart';
import 'widgets/accessible_enhanced_voice_button.dart';
import 'widgets/accessible_transcription_card.dart';
import '/screens/auth/welcome_screen.dart';
import 'screens/environment_recognition_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COMPAS - Asistente de Voz',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFB300),
          secondary: Color(0xFF2E7D32),
          error: Color(0xFFC62828),
          surface: Colors.white,
          onSurface: Color(0xFF212121),
          background: Color(0xFFFAFAFA),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, height: 1.5, color: Color(0xFF212121)),
          bodyMedium: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF424242)),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        ),
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD54F),
          secondary: Color(0xFF66BB6A),
          error: Color(0xFFEF5350),
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
          background: Color(0xFF121212),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, height: 1.5, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFFE0E0E0)),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF1E1E1E),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AccessibleVoiceControlScreen extends StatefulWidget {
  const AccessibleVoiceControlScreen({super.key});

  @override
  AccessibleVoiceControlScreenState createState() => AccessibleVoiceControlScreenState();
}

class AccessibleVoiceControlScreenState extends State<AccessibleVoiceControlScreen>
    with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final TTSService _ttsService = TTSService();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();

  bool _isRecording = false;
  bool _isProcessingAudio = false;
  bool _audioServiceReady = false;

  bool _ttsServiceReady = false;
  bool _ttsEnabled = true;

  String _lastTranscription = '';
  double? _lastConfidence;
  double? _lastProcessingTime;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ÍNDICE DE NAVEGACIÓN INFERIOR
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'Aplicación COMPAS iniciada. Pantalla actual: Reconocimiento de Voz. Use la navegación inferior para cambiar entre funciones',
        TextDirection.ltr,
      );
    });
  }

  Future<void> _initializeServices() async {
    try {
      await _audioService.initialize();
      setState(() => _audioServiceReady = true);
      _showSnackBar('Micrófono listo');
    } catch (e) {
      setState(() => _audioServiceReady = false);
      _showSnackBar('Error de micrófono', isError: true);
    }

    try {
      await _ttsService.initialize();
      setState(() => _ttsServiceReady = true);
    } catch (e) {
      setState(() {
        _ttsServiceReady = false;
        _ttsEnabled = false;
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_audioServiceReady) {
      _showSnackBar('Micrófono no disponible', isError: true);
      return;
    }

    try {
      await _audioService.startRecording();
      setState(() => _isRecording = true);
      HapticFeedback.mediumImpact();
      SemanticsService.announce('Grabando audio', TextDirection.ltr);
    } catch (e) {
      _showSnackBar('Error de grabación', isError: true);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final audioPath = await _audioService.stopRecording();
      setState(() => _isRecording = false);
      HapticFeedback.lightImpact();
      SemanticsService.announce('Procesando audio', TextDirection.ltr);

      if (audioPath != null) {
        await _processAudioFile(audioPath);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showSnackBar('Error al detener grabación', isError: true);
    }
  }

  Future<void> _processAudioFile(String audioPath) async {
    setState(() {
      _isProcessingAudio = true;
      _lastTranscription = '';
    });

    // Aquí puedes implementar tu lógica de procesamiento de audio
    // Por ahora simulo un procesamiento básico
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Simulación de transcripción
      final transcription = 'Audio grabado correctamente en: $audioPath';

      setState(() {
        _lastTranscription = transcription;
        _lastConfidence = 0.95;
        _lastProcessingTime = 1.2;
        _isProcessingAudio = false;
      });

      _showSnackBar('Audio procesado');

      if (_ttsEnabled && _ttsServiceReady) {
        await _ttsService.speakSystemResponse('Audio grabado correctamente');
      }
    } catch (e) {
      setState(() {
        _isProcessingAudio = false;
        _lastTranscription = 'Error: $e';
      });
      _showSnackBar('Error de procesamiento', isError: true);
    }
  }

  Future<void> _processTextCommand() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Campo vacío', isError: true);
      _textFieldFocusNode.requestFocus();
      return;
    }

    try {
      setState(() => _lastTranscription = 'Procesando...');
      SemanticsService.announce('Procesando texto', TextDirection.ltr);

      // Aquí puedes implementar tu lógica de procesamiento de texto
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _lastTranscription = 'Texto recibido: $text';
        _lastConfidence = 1.0;
      });

      _textController.clear();
      _showSnackBar('Texto procesado correctamente');

      if (_ttsEnabled && _ttsServiceReady) {
        await _ttsService.speakSystemResponse('Texto procesado correctamente');
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      _showSnackBar('Error de procesamiento', isError: true);
      setState(() => _lastTranscription = 'Error: $e');
    }
  }

  void _toggleTTS() {
    setState(() => _ttsEnabled = !_ttsEnabled);
    final message = _ttsEnabled ? 'Síntesis de voz activada' : 'Síntesis de voz desactivada';
    _showSnackBar(message);
    if (!_ttsEnabled) _ttsService.stop();
    _ttsService.setEnabled(_ttsEnabled);
    SemanticsService.announce(message, TextDirection.ltr);
  }

  void _onNavigationTap(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);
    HapticFeedback.mediumImpact();

    final screenName = index == 0 ? 'Reconocimiento de Voz' : 'Reconocimiento de Entorno';
    SemanticsService.announce('Navegando a: $screenName', TextDirection.ltr);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    SemanticsService.announce(message, TextDirection.ltr);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    _ttsService.dispose();
    _textController.dispose();
    _textFieldFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // HEADER
              _buildCleanHeader(theme),

              // CONTENIDO DE LAS PANTALLAS
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    // PANTALLA 1: RECONOCIMIENTO DE VOZ
                    _buildVoiceControlTab(theme),

                    // PANTALLA 2: RECONOCIMIENTO DE ENTORNO
                    const EnvironmentRecognitionScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // NAVEGACIÓN INFERIOR
      bottomNavigationBar: _buildAccessibleBottomNav(theme),
    );
  }

  Widget _buildCleanHeader(ThemeData theme) {
    return Semantics(
      label: 'Encabezado de la aplicación',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            // ICONO
            Semantics(
              label: 'Icono de la aplicación',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.accessibility_new_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // TÍTULO
            Expanded(
              child: Semantics(
                header: true,
                label: 'COMPAS - Asistente Accesible',
                child: Text(
                  'COMPAS',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),
            ),

            // BOTÓN DE SÍNTESIS DE VOZ
            if (_currentIndex == 0)
              Semantics(
                label: _ttsEnabled
                    ? 'Desactivar síntesis de voz'
                    : 'Activar síntesis de voz',
                hint: _ttsEnabled
                    ? 'Las respuestas se reproducirán con voz'
                    : 'Las respuestas no se reproducirán',
                button: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                    onPressed: _ttsServiceReady ? _toggleTTS : null,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibleBottomNav(ThemeData theme) {
    return Semantics(
      label: 'Barra de navegación principal con dos opciones',
      container: true,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // BOTÓN 1: RECONOCIMIENTO DE VOZ
              Expanded(
                child: _buildNavButton(
                  theme: theme,
                  icon: Icons.mic_rounded,
                  label: 'Reconocimiento de Voz',
                  index: 0,
                ),
              ),

              // SEPARADOR VISUAL
              Container(
                width: 2,
                height: 50,
                color: theme.colorScheme.onSurface.withOpacity(0.1),
              ),

              // BOTÓN 2: RECONOCIMIENTO DE ENTORNO
              Expanded(
                child: _buildNavButton(
                  theme: theme,
                  icon: Icons.videocam_rounded,
                  label: 'Reconocimiento de Entorno',
                  index: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final baseColor = theme.colorScheme.primary;

    return Semantics(
      label: label,
      hint: isSelected ? 'Pantalla actual' : 'Toque dos veces para navegar',
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNavigationTap(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ICONO CON FONDO
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? baseColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: baseColor, width: 2)
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: isSelected
                        ? baseColor
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),

                const SizedBox(height: 4),

                // INDICADOR DE SELECCIÓN
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 8 : 4,
                  height: isSelected ? 8 : 4,
                  decoration: BoxDecoration(
                    color: isSelected ? baseColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceControlTab(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // BOTÓN DE VOZ GIGANTE
          AccessibleEnhancedVoiceButton(
            isRecording: _isRecording,
            isProcessing: _isProcessingAudio,
            whisperAvailable: _audioServiceReady,
            onStartRecording: _startRecording,
            onStopRecording: _stopRecording,
          ),

          const SizedBox(height: 48),

          // CAMPO DE TEXTO
          _buildTextInput(theme),

          const SizedBox(height: 24),

          // COMANDOS RÁPIDOS
          _buildQuickCommands(theme),

          const SizedBox(height: 24),

          // RESULTADO DE LA TRANSCRIPCIÓN
          if (_lastTranscription.isNotEmpty)
            AccessibleTranscriptionCard(
              transcription: _lastTranscription,
              aiResponse: '',
              confidence: _lastConfidence,
              processingTime: _lastProcessingTime,
              publishedToRos: false,
              autoSpeak: _ttsEnabled && _ttsServiceReady,
            ),

          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildTextInput(ThemeData theme) {
    return Semantics(
      label: 'Campo de texto para ingresar texto manualmente',
      textField: true,
      hint: 'Escriba su texto y presione el botón enviar',
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _textController,
          focusNode: _textFieldFocusNode,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Escribe tu texto aquí',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontSize: 18,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(20),
            suffixIcon: Semantics(
              label: 'Procesar texto',
              hint: 'Toque dos veces para procesar el texto escrito',
              button: true,
              child: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                onPressed: _processTextCommand,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
          onSubmitted: (_) => _processTextCommand(),
          textInputAction: TextInputAction.send,
          maxLines: null,
          minLines: 1,
        ),
      ),
    );
  }

  Widget _buildQuickCommands(ThemeData theme) {
    final commands = ['Hola', 'Prueba de voz', 'Buenos días', 'Gracias'];

    return Semantics(
      label: 'Botones de comandos rápidos. ${commands.length} opciones disponibles',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: commands.map((cmd) => Semantics(
          label: 'Comando rápido: $cmd',
          hint: 'Toque dos veces para usar este comando',
          button: true,
          child: Material(
            color: theme.colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () {
                _textController.text = cmd;
                _processTextCommand();
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Text(
                  cmd,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}