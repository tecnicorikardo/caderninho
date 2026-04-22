import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ModuleTile extends StatefulWidget {
  const ModuleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  State<ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<ModuleTile> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final scale = _isPressed ? 0.965 : (_isHovered ? 1.01 : 1.0);
    final shadowOpacity = _isPressed ? 0.08 : (_isHovered ? 0.22 : 0.15);
    final shadowBlur = _isPressed ? 4.0 : (_isHovered ? 14.0 : 8.0);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: AppTheme.borderGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(shadowOpacity),
              blurRadius: shadowBlur,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                setState(() => _isPressed = value);
              },
              borderRadius: BorderRadius.circular(16),
              splashColor: const Color(0x1F2563EB),
              highlightColor: const Color(0x142563EB),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedScale(
                      scale: _isPressed ? 0.94 : (_isHovered ? 1.05 : 1.0),
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.lightGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Abrir modulo',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
