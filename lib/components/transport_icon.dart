import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';

/// The icon that stands for how an MCP server is reached: a terminal for a local stdio process, a broadcast
/// signal for server-sent events, and a synced cloud for streamable HTTP.
IconData transportIcon(McpTransportType transport) => switch (transport) {
  McpTransportType.stdio => Ic.stdio,
  McpTransportType.sse => Ic.sse,
  McpTransportType.streamHttp => Ic.streamHttp,
};
