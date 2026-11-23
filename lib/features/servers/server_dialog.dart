import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/segmented.dart';
import 'package:rocket_mcp/components/tables.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/components/transport_icon.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/storage/server_store.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Modal dialog for adding or editing an MCP server configuration.
class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key, required this.state, this.server});

  final AppState state;
  final McpServerConfig? server;

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late String _name;
  late McpTransportType _transport;
  late String _command;
  late String _argsText;
  late List<TableKV> _envRows;
  late String _workingDirectory;
  late String _url;
  late List<TableKV> _headerRows;
  late bool _autoConnect;

  @override
  void initState() {
    super.initState();
    final s = widget.server;
    _name = s?.name ?? 'New Server';
    _transport = s?.transport ?? McpTransportType.stdio;
    _command = s?.command ?? 'npx';
    _argsText = s?.args.join(' ') ?? '';
    _envRows =
        s?.env.entries
            .map((e) => TableKV(name: e.key, value: e.value))
            .toList() ??
        [];
    _workingDirectory = s?.workingDirectory ?? '';
    _url = s?.url ?? 'http://localhost:3001/sse';
    _headerRows =
        s?.headers.entries
            .map((e) => TableKV(name: e.key, value: e.value))
            .toList() ??
        [];
    _autoConnect = s?.autoConnect ?? false;
  }

  void _applyPreset(McpServerConfig preset) {
    setState(() {
      _name = preset.name;
      _transport = preset.transport;
      _command = preset.command;
      _argsText = preset.args.join(' ');
      _envRows = preset.env.entries
          .map((e) => TableKV(name: e.key, value: e.value))
          .toList();
      _headerRows = preset.headers.entries
          .map((e) => TableKV(name: e.key, value: e.value))
          .toList();
      _url = preset.url;
    });
  }

  void _save() {
    final nameTrimmed = _name.trim();
    if (nameTrimmed.isEmpty) {
      widget.state.showToast('Server name is required');
      return;
    }

    final argsList = _argsText
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    final envMap = <String, String>{};
    for (final r in _envRows) {
      if (r.enabled && r.name.trim().isNotEmpty) {
        envMap[r.name.trim()] = r.value.trim();
      }
    }

    final headersMap = <String, String>{};
    for (final r in _headerRows) {
      if (r.enabled && r.name.trim().isNotEmpty) {
        headersMap[r.name.trim()] = r.value.trim();
      }
    }

    final id =
        widget.server?.id ?? 'server_${DateTime.now().microsecondsSinceEpoch}';
    final updated = McpServerConfig(
      id: id,
      name: nameTrimmed,
      transport: _transport,
      command: _command.trim(),
      args: argsList,
      env: envMap,
      workingDirectory: _workingDirectory.trim().isEmpty
          ? null
          : _workingDirectory.trim(),
      url: _url.trim(),
      headers: headersMap,
      autoConnect: _autoConnect,
    );

    if (widget.server != null) {
      widget.state.updateServer(updated);
      widget.state.showToast('Server "${updated.name}" updated');
    } else {
      widget.state.addServer(updated);
      widget.state.showToast('Server "${updated.name}" added');
    }

    widget.state.modal = null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isEdit = widget.server != null;

    return ModalBox(
      title: isEdit ? 'Configurations' : 'Add MCP Server',
      width: 640,
      onClose: () => widget.state.modal = null,
      actions: [
        Btn(label: 'Cancel', onClick: () => widget.state.modal = null),
        Btn(
          label: isEdit ? 'Save Changes' : 'Add Server',
          primary: true,
          onClick: _save,
        ),
      ],
      content: [
        if (!isEdit) ...[
          const SectionLabel('QUICK TEMPLATES'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 6,
              children: [
                for (final preset in ServerStore.builtInPresets)
                  Clickable(
                    onClick: () => _applyPreset(preset),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.hover,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        spacing: 4,
                        children: [
                          Ico(
                            transportIcon(preset.transport),
                            size: 13,
                            tint: p.accent,
                          ),
                          T(preset.name.split('(').first.trim(), size: 11),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
        const SectionLabel('SERVER NAME'),
        Field(
          value: _name,
          onChange: (v) => setState(() => _name = v),
          placeholder: 'e.g. Everything Server, Filesystem, SQLite',
        ),
        const SizedBox(height: 4),
        const SectionLabel('TRANSPORT TYPE'),
        Segmented(
          options: const ['STDIO', 'SSE', 'Streamable HTTP'],
          selected: switch (_transport) {
            McpTransportType.stdio => 'STDIO',
            McpTransportType.sse => 'SSE',
            McpTransportType.streamHttp => 'Streamable HTTP',
          },
          onSelect: (opt) {
            setState(() {
              _transport = switch (opt) {
                'STDIO' => McpTransportType.stdio,
                'SSE' => McpTransportType.sse,
                _ => McpTransportType.streamHttp,
              };
            });
          },
        ),
        const SizedBox(height: 4),
        if (_transport == McpTransportType.stdio) ...[
          const SectionLabel('COMMAND'),
          Field(
            value: _command,
            onChange: (v) => setState(() => _command = v),
            placeholder: 'e.g. npx, uvx, python, node, /path/to/binary',
            mono: true,
          ),
          const SectionLabel('ARGUMENTS (SPACE-SEPARATED)'),
          Field(
            value: _argsText,
            onChange: (v) => setState(() => _argsText = v),
            placeholder: 'e.g. -y @modelcontextprotocol/server-everything',
            mono: true,
          ),
          const SectionLabel('WORKING DIRECTORY (OPTIONAL)'),
          Field(
            value: _workingDirectory,
            onChange: (v) => setState(() => _workingDirectory = v),
            placeholder: 'e.g. /Users/you/project',
            mono: true,
          ),
          const SizedBox(height: 2),
          const SectionLabel('ENVIRONMENT VARIABLES'),
          EditableKVTable(
            items: _envRows,
            onChange: (rows) => setState(() => _envRows = rows),
            keyHint: 'ENV_VAR',
            valHint: 'value',
            keyTitle: 'VARIABLE',
            valTitle: 'VALUE',
          ),
        ] else ...[
          SectionLabel(
            _transport == McpTransportType.streamHttp
                ? 'ENDPOINT URL (STREAMABLE HTTP)'
                : 'SSE URL (SERVER-SENT EVENTS)',
          ),
          Field(
            value: _url,
            onChange: (v) => setState(() => _url = v),
            placeholder: _transport == McpTransportType.streamHttp
                ? 'http://localhost:8000/mcp'
                : 'http://localhost:3001/sse',
            mono: true,
          ),
          const SizedBox(height: 2),
          const SectionLabel('HTTP HEADERS'),
          EditableKVTable(
            items: _headerRows,
            onChange: (rows) => setState(() => _headerRows = rows),
            keyHint: 'Header-Name',
            valHint: 'Header-Value',
            keyTitle: 'HEADER',
            valTitle: 'VALUE',
          ),
        ],
        const SizedBox(height: 6),
        LabeledCheck(
          label: 'Connect automatically on startup',
          checked: _autoConnect,
          onChange: (v) => setState(() => _autoConnect = v),
        ),
      ],
    );
  }
}
