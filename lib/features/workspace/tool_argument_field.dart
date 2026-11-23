import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/layout.dart' show CONTROL_H;
import 'package:rocket_mcp/components/overlay.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/components/item_tile.dart';
import 'package:rocket_mcp/components/toggle.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// The input for one argument of a tool, chosen from its JSON schema: a switch for booleans, a drop-down for enums,
/// a JSON editor for arrays and objects, and a text field (monospace for numbers) for everything else. It shows the
/// argument's name, a required marker, its type, its description, and a red outline when a required value is missing.
class ToolArgumentField extends StatelessWidget {
  const ToolArgumentField({
    super.key,
    required this.name,
    required this.schema,
    required this.isRequired,
    required this.value,
    required this.onChange,
    this.showError = false,
    this.focusNode,
  });

  final String name;
  final Map<dynamic, dynamic> schema;
  final bool isRequired;

  /// The current value: a string, number, bool, list or map, or null when unset.
  final Object? value;
  final ValueChanged<Object?> onChange;

  /// Outlines the input and reddens the name; set when a required value is missing after a run was attempted.
  final bool showError;

  /// Lets the caller focus this argument's text input (text, number and JSON inputs; not switches or drop-downs).
  final FocusNode? focusNode;

  String get _type => schema['type']?.toString() ?? 'string';
  String? get _description => schema['description']?.toString();
  List<String> get _options => [
    for (final o
        in (schema['enum'] is List ? schema['enum'] as List : const []))
      o.toString(),
  ];
  String? get _default => schema['default']?.toString();

  String get _typeLabel => _options.isNotEmpty ? 'enum' : _type;

  /// A flat, cardless field: the name with its marker and type, the description, then the input, all stacked.
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final description = _description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          spacing: 6,
          children: [
            Flexible(
              child: T(
                name,
                size: 12.5,
                lineHeight: 1.4,
                weight: FontWeight.w600,
                color: showError ? p.err : null,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isRequired)
              T(
                '*',
                color: p.err,
                size: 12.5,
                lineHeight: 1.4,
                weight: FontWeight.w700,
              ),
            TileBadge(_typeLabel),
          ],
        ),
        if (description != null && description.isNotEmpty)
          T(description, size: 11, lineHeight: 1.5, color: p.muted),
        _input(context),
      ],
    );
  }

  Widget _input(BuildContext context) {
    final p = context.pal;
    final Widget input;
    if (_type == 'boolean') {
      // Same footprint as a text input: a control row that is as tall as the other inputs.
      input = Container(
        height: CONTROL_H,
        alignment: Alignment.centerLeft,
        child: Row(
          spacing: 10,
          children: [
            Toggle(on: value == true, onChange: onChange),
            T(
              value == true ? 'Enabled' : 'Disabled',
              size: 12,
              color: value == true ? p.text : p.muted,
            ),
          ],
        ),
      );
    } else if (_options.isNotEmpty) {
      final current = value?.toString() ?? '';
      input = Dropdown(
        expand: true,
        selected: current.isEmpty ? 'Select…' : current,
        color: current.isEmpty ? p.muted : null,
        options: _options,
        onSelect: onChange,
      );
    } else if (_type == 'array' || _type == 'object') {
      final text = value is String
          ? value as String
          : (value == null
                ? ''
                : const JsonEncoder.withIndent('  ').convert(value));
      input = AreaField(
        value: text,
        onChange: (v) {
          try {
            onChange(jsonDecode(v));
          } catch (_) {
            onChange(v);
          }
        },
        placeholder: _type == 'array' ? '[ ]' : '{ }',
        minHeight: 84,
        maxLines: 12,
        mono: true,
        focusRequester: focusNode,
      );
    } else {
      final numeric = _type == 'number' || _type == 'integer';
      input = Field(
        value: value?.toString() ?? '',
        onChange: (v) => onChange(numeric ? (num.tryParse(v) ?? v) : v),
        placeholder: _default != null ? 'Default: $_default' : 'Enter $name…',
        mono: numeric,
        highlightVars: false,
        focusRequester: focusNode,
      );
    }
    if (!showError) return input;
    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.err),
      ),
      child: input,
    );
  }
}
