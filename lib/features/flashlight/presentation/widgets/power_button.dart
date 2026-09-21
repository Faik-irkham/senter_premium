import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PowerButton extends StatelessWidget {
  const PowerButton({
    super.key,
    required this.isOn,
    required this.isLocked,
    required this.onPressed,
    this.isBusy = false,
    this.size = 180,
  });

  final bool isOn;

  final bool isLocked;
  final bool isBusy;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isOn ? 'Matikan senter' : 'Nyalakan senter',
      child: GestureDetector(
        onTap: isBusy ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn ? AppColors.gold : AppColors.surface,
            border: Border.all(
              color: isOn ? AppColors.beam : Colors.white12,
              width: size * 0.017,
            ),
            boxShadow: [
              if (isOn)
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.6),
                  blurRadius: size * 0.44,
                  spreadRadius: size * 0.11,
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.power_settings_new,
                size: size * 0.44,
                color: isOn ? AppColors.background : AppColors.gold,
              ),
              if (isLocked)
                Positioned(
                  right: size * 0.155,
                  bottom: size * 0.155,
                  child: Icon(
                    Icons.lock,
                    size: size * 0.145,
                    color: AppColors.background,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
