import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/code_view.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';

/// Allows crafting and sending arbitrary JSON-RPC requests directly.
class RawJsonRpcView extends StatelessWidget {
  const RawJsonRpcView({super.key, required this.session});
  final McpSession session;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    const SectionLabel('METHOD'),
                    Field(
                      value: session.rawMethod,
                      onChange: (v) => session.rawMethod = v,
                      placeholder: 'e.g. tools/list, ping, resources/read, custom/method',
                      mono: true,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Btn(
                  label: session.isRunningRaw ? 'Sending…' : 'Send Request',
                  icon: Ic.send,
                  primary: true,
                  enabled:
                      !session.isRunningRaw &&
                      session.rawMethod.trim().isNotEmpty &&
                      session.status == McpServerStatus.connected,
                  onClick: session.sendRawJsonRpc,
                ),
              ),
            ],
          ),
          const SectionLabel('PARAMETERS (JSON OBJECT)'),
          AreaField(
            value: session.rawParams,
            onChange: (v) => session.rawParams = v,
            placeholder: '{\n  "key": "value"\n}',
            minHeight: 180,
            mono: true,
          ),
          if (session.lastRawResponse != null) ...[
            const SectionLabel('RAW RESPONSE'),
            SizedBox(
              height: 260,
              child: CodeView(text: session.lastRawResponse!, lang: 'json'),
            ),
          ],
        ],
      ),
    );
  }
}
