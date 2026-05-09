import 'package:flutter/material.dart';

enum PPButtonVariant { primary, secondary }

class PPButton extends StatelessWidget {
  const PPButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PPButtonVariant.primary,
    this.loading = false,
    this.fullWidth = false,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final PPButtonVariant variant;
  final bool loading;
  final bool fullWidth;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onPressed == null || loading;
    final primaryBg = backgroundColor ?? scheme.primary;
    final primaryFg = foregroundColor ?? scheme.onPrimary;
    final secondaryFg = foregroundColor ?? scheme.primary;
    final secondaryBorder = borderColor ?? scheme.primary;

    final baseStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(56, 48)),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: WidgetStateProperty.all(
        Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    final Widget child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == PPButtonVariant.primary ? primaryFg : secondaryFg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: 18,
                    color: variant == PPButtonVariant.primary ? primaryFg : secondaryFg,
                  ),
                  child: leading!,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      PPButtonVariant.primary => ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: baseStyle.merge(
            ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled) ? primaryBg.withValues(alpha: 0.45) : primaryBg,
              ),
              foregroundColor: WidgetStateProperty.all(primaryFg),
              elevation: WidgetStateProperty.all(0),
            ),
          ),
          child: child,
        ),
      PPButtonVariant.secondary => OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: baseStyle.merge(
            ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled) ? secondaryFg.withValues(alpha: 0.55) : secondaryFg,
              ),
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.disabled)
                      ? (borderColor ?? scheme.outline).withValues(alpha: 0.6)
                      : secondaryBorder,
                ),
              ),
            ),
          ),
          child: child,
        ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

