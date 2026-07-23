import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';

/// Label-above text field used across forms. Optional fields are marked in
/// the label so required fields stay visually quiet.
class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.label,
    this.controller,
    this.optional = false,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.prefixText,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final bool optional;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final String? prefixText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldLabel(label: label, optional: optional),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        onChanged: onChanged,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        enabled: enabled,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hint,
          helperText: helper,
          helperMaxLines: 2,
          errorText: errorText,
          errorMaxLines: 2,
          prefixText: prefixText,
          counterText: '',
        ),
      ),
    ],
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, this.optional = false});
  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
      if (optional) ...[
        const SizedBox(width: 6),
        Text('Optional', style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );
}

/// Groups Ghana mobile numbers as "24 555 0192" while typing.
class GhanaPhoneFormatter extends TextInputFormatter {
  const GhanaPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 9 ? digits.substring(0, 9) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 2 || i == 5) buffer.write(' ');
      buffer.write(trimmed[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String? ghanaPhoneValidator(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Enter your phone number to continue.';
  if (digits.length < 9) {
    return 'Enter the 9 digits after +233, e.g. 24 555 0192.';
  }
  return null;
}

/// Phone entry with a fixed dial-code prefix.
class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    this.label = 'Phone number',
    this.dialCode = '+233',
    this.helper,
    this.errorText,
    this.validator = ghanaPhoneValidator,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String dialCode;
  final String? helper;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldLabel(label: label),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        autofocus: autofocus,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        inputFormatters: const [GhanaPhoneFormatter()],
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: '24 555 0192',
          helperText: helper,
          helperMaxLines: 2,
          errorText: errorText,
          errorMaxLines: 2,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Text(
              dialCode,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
        ),
      ),
    ],
  );
}

/// Currency entry with a fixed GH₵ prefix.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.label,
    required this.controller,
    this.symbol = 'GH₵',
    this.helper,
    this.optional = false,
    this.validator,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String symbol;
  final String? helper;
  final bool optional;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldLabel(label: label, optional: optional),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}\.?\d{0,2}')),
        ],
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '0.00',
          helperText: helper,
          helperMaxLines: 2,
          errorMaxLines: 2,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Text(
              symbol,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
        ),
      ),
    ],
  );
}

/// A tappable row that opens a picker; shows the current value or a
/// placeholder. Sized and bordered like a text field for visual rhythm.
class SelectionRow extends StatelessWidget {
  const SelectionRow({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.errorText,
    this.optional = false,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final String? errorText;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, optional: optional),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: '$label: ${value ?? placeholder}',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: AppSizes.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: hasError ? AppColors.danger : AppColors.line,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: value == null ? AppColors.muted : AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: InlineError(message: errorText!),
          ),
      ],
    );
  }
}

/// A large selectable option with a title, supporting text and an optional
/// leading widget. One decision per screen; two to four of these per screen.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$title. $subtitle',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.mint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.forest : AppColors.line,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Inline error with an icon, announced by screen readers.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12.5, color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
}

/// Bottom-sheet single-select picker used by [SelectionRow].
Future<T?> showOptionPicker<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T option) labelOf,
  T? selected,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(labelOf(option)),
                    trailing: option == selected
                        ? const Icon(Icons.check, color: AppColors.forest)
                        : null,
                    onTap: () => Navigator.pop(context, option),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
