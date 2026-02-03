// lib/widgets/ai_mode_debug_widget.dart
// ✅ WIDGET DE DEBUG PARA CAMBIAR ENTRE MODO ONLINE/OFFLINE

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/AI/ai_mode_controller.dart';

/// Widget flotante para cambiar modo de IA (solo debug)
class AIModeDebugWidget extends StatefulWidget {
  const AIModeDebugWidget({super.key});

  @override
  State<AIModeDebugWidget> createState() => _AIModeDebugWidgetState();
}

class _AIModeDebugWidgetState extends State<AIModeDebugWidget> {
  final AIModeController _controller = AIModeController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Escuchar cambios
    _controller.onModeChanged = (mode) {
      if (mounted) setState(() {});
    };

    _controller.onConnectivityChanged = (hasInternet) {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveMode = _controller.effectiveMode;
    final hasInternet = _controller.hasInternet;

    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() => _isExpanded = !_isExpanded);
          HapticFeedback.mediumImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: effectiveMode == AIMode.online
                  ? Colors.green
                  : Colors.orange,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (effectiveMode == AIMode.online
                    ? Colors.green
                    : Colors.orange).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    effectiveMode == AIMode.online
                        ? Icons.cloud
                        : Icons.offline_bolt,
                    color: effectiveMode == AIMode.online
                        ? Colors.green
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    effectiveMode == AIMode.online ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: effectiveMode == AIMode.online
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),

              // CONTENIDO EXPANDIDO
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Container(
                  width: 200,
                  height: 1,
                  color: Colors.white24,
                ),
                const SizedBox(height: 12),

                // INDICADOR DE INTERNET
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasInternet
                          ? Icons.wifi
                          : Icons.wifi_off,
                      color: hasInternet
                          ? Colors.green
                          : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasInternet ? 'Conectado' : 'Sin conexión',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // INDICADOR DE GEMINI
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _controller.geminiAvailable
                          ? Icons.check_circle
                          : Icons.warning,
                      color: _controller.geminiAvailable
                          ? Colors.green
                          : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _controller.geminiAvailable
                          ? 'Gemini OK'
                          : 'Gemini N/A',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // BOTONES DE MODO
                _buildModeButton(
                  mode: AIMode.auto,
                  icon: Icons.autorenew,
                  label: 'Auto',
                  theme: theme,
                ),

                const SizedBox(height: 6),

                _buildModeButton(
                  mode: AIMode.online,
                  icon: Icons.cloud,
                  label: 'Online (Gemini)',
                  theme: theme,
                  enabled: _controller.geminiAvailable && hasInternet,
                ),

                const SizedBox(height: 6),

                _buildModeButton(
                  mode: AIMode.offline,
                  icon: Icons.offline_bolt,
                  label: 'Offline (Local)',
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required AIMode mode,
    required IconData icon,
    required String label,
    required ThemeData theme,
    bool enabled = true,
  }) {
    final isSelected = _controller.currentMode == mode;

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled
              ? () {
            _controller.setMode(mode);
            HapticFeedback.lightImpact();

            // Mensaje de confirmación
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Modo cambiado a: ${mode.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: theme.colorScheme.secondary,
                duration: const Duration(seconds: 1),
              ),
            );
          }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// USO EN AR_NAVIGATION_SCREEN:
// ═══════════════════════════════════════════════════════════════════
//
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     body: Stack(
//       children: [
//         // ... tu contenido actual
//
//         // ✅ AGREGAR WIDGET DE DEBUG
//         const AIModeDebugWidget(),
//       ],
//     ),
//   );
// }
//