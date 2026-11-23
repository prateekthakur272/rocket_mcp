import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/storage/server_store.dart';
import 'package:rocket_mcp/theme/icons.dart';

/// Modal dialog for importing and exporting MCP server configurations.
class ImportExportDialog extends StatefulWidget {
  const ImportExportDialog({super.key, required this.state});
  final AppState state;

  @override
  State<ImportExportDialog> createState() => _ImportExportDialogState();
}

class _ImportExportDialogState extends State<ImportExportDialog> {
  String _tab = 'Import';
  String _importText = '';
  late String _exportText;

  @override
  void initState() {
    super.initState();
    _exportText = ServerStore.exportClaudeFormat(widget.state.servers);
  }

  void _doImport() {
    final text = _importText.trim();
    if (text.isEmpty) {
      widget.state.showToast('Please paste a JSON configuration to import');
      return;
    }

    try {
      final imported = ServerStore.importFromJson(text);
      if (imported.isEmpty) {
        widget.state.showToast('No valid servers found in JSON');
        return;
      }

      widget.state.importServers(imported);
      widget.state.showToast(
        'Successfully imported ${imported.length} server(s)',
      );
      widget.state.modal = null;
    } catch (e) {
      widget.state.showToast('Import error: $e');
    }
  }

  void _copyExport() {
    Clipboard.setData(ClipboardData(text: _exportText));
    widget.state.showToast('Configuration copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return ModalBox(
      title: 'Import / Export MCP Servers',
      width: 640,
      onClose: () => widget.state.modal = null,
      actions: [
        if (_tab == 'Import') ...[
          Btn(label: 'Cancel', onClick: () => widget.state.modal = null),
          Btn(label: 'Import Servers', primary: true, onClick: _doImport),
        ] else ...[
          Btn(
            label: 'Copy JSON',
            icon: Ic.copy,
            primary: true,
            onClick: _copyExport,
          ),
          Btn(label: 'Done', onClick: () => widget.state.modal = null),
        ],
      ],
      content: [
        Tabs(
          items: const ['Import', 'Export'],
          selected: _tab,
          onSelect: (t) => setState(() => _tab = t),
        ),
        const SizedBox(height: 6),
        if (_tab == 'Import') ...[
          const T(
            'Paste your Claude Desktop configuration (claude_desktop_config.json) or Rocket MCP JSON below:',
            size: 12,
          ),
          AreaField(
            value: _importText,
            onChange: (v) => setState(() => _importText = v),
            placeholder: '{\n  "mcpServers": {\n    "my-server": {\n      "command": "npx",\n      "args": ["-y", "@modelcontextprotocol/server-everything"]\n    }\n  }\n}',
            minHeight: 220,
            mono: true,
          ),
        ] else ...[
          const T(
            'Your current server configurations formatted for Claude Desktop and MCP clients:',
            size: 12,
          ),
          AreaField(
            value: _exportText,
            onChange: (v) => setState(() => _exportText = v),
            minHeight: 220,
            mono: true,
          ),
        ],
      ],
    );
  }
}
