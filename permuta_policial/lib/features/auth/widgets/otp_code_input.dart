import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permuta_policial/core/config/app_theme.dart';

/// Campo OTP de 6 dígitos com caixas, auto-avanço e suporte a colar código completo.
class OtpCodeInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final int length;

  const OtpCodeInput({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.length = 6,
  });

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _notify() {
    final code = _code;
    widget.onChanged(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _pasteCode(value);
      return;
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _notify();
  }

  void _pasteCode(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final focusIndex = digits.length.clamp(0, widget.length - 1);
    _focusNodes[focusIndex].requestFocus();
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (index) {
          return SizedBox(
            width: 44,
            height: 52,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction:
                  index == widget.length - 1 ? TextInputAction.done : TextInputAction.next,
              autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: InputDecoration(
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: AppTheme.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              onChanged: (v) => _onChanged(index, v),
              onTap: () {
                // Seleciona o conteúdo ao focar para facilitar substituição
                _controllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controllers[index].text.length,
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
