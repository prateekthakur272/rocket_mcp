import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';

void main() {
  test('many messages sent at once all reach the process, in order', () async {
    // `cat` echoes every line it receives, which is what a server answering requests looks like from here.
    final transport = McpStdioTransport(command: 'cat');
    final received = <Map<String, dynamic>>[];
    final sub = transport.incoming.listen(received.add);
    await transport.connect();

    const count = 40;
    await Future.wait([
      for (var i = 0; i < count; i++)
        transport.send({'jsonrpc': '2.0', 'id': i, 'method': 'ping'}),
    ]);

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (received.length < count && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(
      [for (final m in received) m['id']],
      [for (var i = 0; i < count; i++) i],
    );

    await sub.cancel();
    await transport.close();
  }, skip: Platform.isWindows ? 'needs the cat command' : null);
}
