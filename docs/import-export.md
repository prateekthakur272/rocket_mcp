# Import and export

Open **Import** (header, sidebar, **⌘⇧I / Ctrl+Shift+I** or the command palette) to move server configurations in and out of Rocket MCP. The dialog has the same name, **Import / Export MCP Servers**, for both directions.

## Import

Paste JSON into the box and press **Import Servers**. Rocket MCP understands three shapes:

**A Claude Desktop configuration** (`claude_desktop_config.json`), the most common one:

```json
{
  "mcpServers": {
    "everything": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-everything"],
      "env": { "DEBUG": "1" }
    },
    "remote": {
      "url": "https://example.com/mcp",
      "headers": { "Authorization": "Bearer <token>" }
    }
  }
}
```

An entry with a `command` becomes a stdio server; an entry with a `url` becomes a remote server (streamable HTTP, or SSE when the entry says so). The key is used as the server's name.

**A list of Rocket MCP servers**, the same objects that are stored in `servers.json` (see [data and storage](data-and-storage.md)).

**A single Rocket MCP server object** with a `name`, `command` or `url`.

If nothing valid is found you are told so and nothing is added. Imported servers are added to your list and the first one is selected.

## Export

The lower half of the dialog shows your current servers in the Claude Desktop format. **Copy JSON** puts it on the clipboard, ready to paste into another MCP client's configuration.

The Claude format only carries what other clients understand:

| Kept | Not carried |
|---|---|
| stdio: command, arguments, environment variables | Working directory, auto-connect |
| remote: URL, headers | The server's id |

Back up your servers in full by copying `servers.json` from the data folder instead.
