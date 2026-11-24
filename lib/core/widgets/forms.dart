import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/widgets/branding.dart';
import 'package:grid_professionals/core/widgets/patterns.dart';

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
    this.initialValue,
  });

  final String label;
  final TextEditingController? controller;

  /// Starting text when there is no [controller].
  final String? initialValue;
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
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        keyboardType: keyboardType,
        style: AppText.body.copyWith(
          color: enabled ? AppColors.ink : AppColors.muted,
        ),
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
        child: Text(
          label,
          style: AppText.label.copyWith(fontSize: 14, color: AppColors.ink),
        ),
      ),
      if (optional) ...[
        const SizedBox(width: 6),
        Text('Optional', style: AppText.caption.copyWith(fontSize: 12)),
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
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    // People type their number the way they say it — "024…" or "233…".
    if (digits.startsWith('233') && digits.length > 9) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
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
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The dial code sits in its own box rather than inside the field, so
          // the number the provider types is never crowded by it.
          Container(
            height: AppSizes.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: AppColors.lineStrong),
            ),
            alignment: Alignment.center,
            child: Text(
              dialCode,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                fontFeatures: AppText.tabular,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: autofocus,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: const [GhanaPhoneFormatter()],
              validator: validator,
              onChanged: onChanged,
              onFieldSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
                fontFeatures: AppText.tabular,
              ),
              decoration: InputDecoration(
                hintText: '24 555 0192',
                helperText: helper,
                helperMaxLines: 2,
                errorText: errorText,
                errorMaxLines: 2,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Six-cell verification code entry.
///
/// The cells are painted, not focusable: a single transparent field sits over
/// them and owns the text. That keeps paste, autofill and the OS one-time-code
/// suggestion working, none of which survive one field per digit.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.hasError = false,
    this.autofocus = true,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _focus.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _handleChange(String value) {
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final active = _focus.hasFocus ? code.length : -1;
    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              Expanded(
                child: _OtpCell(
                  digit: i < code.length ? code[i] : '',
                  active:
                      i == active ||
                      (active == widget.length && i == active - 1),
                  hasError: widget.hasError,
                ),
              ),
              if (i != widget.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        Positioned.fill(
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.length),
            ],
            showCursor: false,
            enableInteractiveSelection: false,
            onChanged: _handleChange,
            // Invisible: the painted cells above are the real UI.
            style: const TextStyle(color: Colors.transparent, height: 1),
            decoration: const InputDecoration(
              counterText: '',
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.digit,
    required this.active,
    required this.hasError,
  });
  final String digit;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final border = hasError
        ? AppColors.danger
        : active
        ? AppColors.navy
        : digit.isEmpty
        ? AppColors.lineStrong
        : AppColors.faint;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: digit.isEmpty && !active
            ? AppColors.surfaceSubtle
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: border, width: active || hasError ? 1.8 : 1),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          fontFeatures: AppText.tabular,
        ),
      ),
    );
  }
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
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppText.body.copyWith(
          fontWeight: FontWeight.w600,
          fontFeatures: AppText.tabular,
        ),
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
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: '$label: ${value ?? placeholder}',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.field),
            child: Container(
              height: AppSizes.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(
                  color: hasError ? AppColors.danger : AppColors.lineStrong,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: value == null ? AppColors.faint : AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.faint,
                  ),
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

/// A large selectable option with a title, supporting text, an optional
/// leading widget and a radio. One decision per screen; two to four of these.
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
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.line,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.subtitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppText.caption.copyWith(fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            RadioDot(selected: selected),
          ],
        ),
      ),
    ),
  );
}

/// Icon on a soft navy tile, for the leading slot of a [ChoiceCard].
class ChoiceIcon extends StatelessWidget {
  const ChoiceIcon(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: AppColors.navySoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: AppColors.navy, size: 22),
  );
}

/// Painted radio indicator for custom selectable cards.
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? Colors.white : Colors.transparent,
      border: Border.all(
        color: selected ? AppColors.navy : AppColors.lineStrong,
        width: selected ? 6.5 : 1.6,
      ),
    ),
  );
}

/// Painted check box for multi-select rows and cards.
class CheckMark extends StatelessWidget {
  const CheckMark({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 140),
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: selected ? AppColors.navy : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: selected ? AppColors.navy : AppColors.lineStrong,
        width: 1.6,
      ),
    ),
    child: selected
        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
        : null,
  );
}

/// One row of a multi-select list, with a check box on the right.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.body.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CheckMark(selected: selected),
          ],
        ),
      ),
    ),
  );
}

/// Bordered list of [CheckRow]s.
class CheckList extends StatelessWidget {
  const CheckList({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        for (final option in options) ...[
          CheckRow(
            label: option,
            selected: selected.contains(option),
            onChanged: (value) => onChanged(
              value
                  ? [...selected, option]
                  : selected.where((item) => item != option).toList(),
            ),
          ),
          if (option != options.last) const Divider(),
        ],
      ],
    ),
  );
}

/// Phone entry presented as the subject of the screen: a tinted card with
/// the number set large, the way the provider reads it aloud. The screen
/// validates and passes any message in as [errorText].
class PhoneHeroField extends StatelessWidget {
  const PhoneHeroField({
    super.key,
    required this.controller,
    this.label = 'Enter your phone number',
    this.dialCode = '+233',
    this.errorText,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String dialCode;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    const numberStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: AppColors.ink,
      height: 1.2,
      fontFeatures: AppText.tabular,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.navySoft,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              const CornerArcs(color: Color(0xFFDCE4F0), size: 130),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        GridGlyph(size: 20),
                        SizedBox(width: 8),
                        Text(
                          'GRID Pro',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: AppColors.muted,
                        ),
                        SizedBox(width: 4),
                        Text('Secure', style: AppText.caption),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(label, style: AppText.caption.copyWith(fontSize: 14)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          dialCode,
                          style: numberStyle.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            keyboardType: TextInputType.phone,
                            autofocus: autofocus,
                            autofillHints: const [
                              AutofillHints.telephoneNumberNational,
                            ],
                            inputFormatters: const [GhanaPhoneFormatter()],
                            onFieldSubmitted: onSubmitted,
                            cursorColor: AppColors.navy,
                            cursorWidth: 2.5,
                            style: numberStyle,
                            decoration: InputDecoration(
                              hintText: '24 555 0192',
                              hintStyle: numberStyle.copyWith(
                                color: AppColors.lineStrong,
                              ),
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: InlineError(message: errorText!),
          ),
      ],
    );
  }
}

/// A setting with a title, a line of explanation and a switch, in a card.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: '$title. $subtitle',
    excludeSemantics: true,
    child: InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.subtitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(value: value, onChanged: onChanged),
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              8,
            ),
            child: Text(title, style: AppText.title),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    title: Text(
                      labelOf(option),
                      style: AppText.body.copyWith(
                        fontWeight: option == selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: RadioDot(selected: option == selected),
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
