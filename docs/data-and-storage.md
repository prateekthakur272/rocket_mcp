# Data and storage

Rocket MCP keeps everything it remembers in one folder in your home directory, and nothing anywhere else. It does not use the system preference store, and it sends nothing over the network except what you ask it to (your connections to MCP servers, and an optional check for a newer release on GitHub).

**Help ▸ Open Storage Folder** (or **⌘⇧O**) shows it.

| System | Folder |
|---|---|
| macOS, Linux | `~/.rocketmcp` |
| Windows | `%USERPROFILE%\.rocketmcp` |

## Files

| File | Holds |
|---|---|
| `servers.json` | Your servers |
| `settings.json` | Preferences |
| `layout.json` | Sidebar width and visibility, list width, request / response split |
| `prefs.json` | Small flags, for example that the welcome tour is done and which update you dismissed |
| `window.json` | Window size and position |
| `rocketmcp.log` | A log of warnings and errors, kept under 1 MB (the older half moves to `rocketmcp.log.old`) |

All of them are plain JSON apart from the log. Settings are written the moment you change them; layout shortly after you stop dragging; the window when you quit. A file that cannot be read is ignored and its defaults are used, with a note in the log.

## `servers.json`

A list of server objects:

```json
[
  {
    "id": "weather",
    "name": "Weather Server",
    "transport": "stdio",
    "command": "npx",
    "args": ["-y", "@acme/mcp-weather"],
    "env": { "WEATHER_API_KEY": "…" },
    "workingDirectory": "/Users/you/projects/weather",
    "url": "",
    "headers": {},
    "autoConnect": false
  },
  {
    "id": "notes",
    "name": "Notes Server",
    "transport": "streamHttp",
    "command": "",
    "args": [],
    "env": {},
    "url": "https://notes.example.com/mcp",
    "headers": { "Authorization": "Bearer …" },
    "autoConnect": true
  }
]
```

`transport` is `stdio`, `sse` or `streamHttp`. `workingDirectory` is optional. Everything else is always written.

> Environment variables and headers are stored here **in plain text**, so a token you put in a header is in this file. Treat the file as you would treat the token, and do not commit it to a public repository.

## `settings.json`

| Key | Meaning | Default |
|---|---|---|
| `theme` | `system`, `light` or `dark` | `system` |
| `fontSize` | Interface size, 10 to 20 | `13` |
| `verticalLayout` | `true` stacks the response below the request, `false` puts it beside | `true` |
| `autoSave` | Save tool parameters and prompt fields before a request is sent | `false` |
| `timeoutMs` | How long to wait for an answer; `0` for no limit | `30000` |
| `userAgent` | Sent over HTTP transports; empty uses `Rocket MCP/<version>` | empty |
| `sslVerify` | Verify certificates of HTTPS servers | `true` |
| `proxyEnabled`, `proxyHost`, `proxyPort` | An HTTP proxy for connections | off, empty, `8080` |

**Preferences ▸ Data ▸ Reset preferences** restores these defaults and leaves your servers alone.

## `layout.json`

`sidebarWidth` (a fraction of the window), `sidebarVisible`, `listPaneWidth` (device-independent pixels, for the Tools, Resources and Prompts lists) and `splitFraction` (the share of the workspace taken by the request pane).

## Starting fresh

Quit Rocket MCP and move or delete the folder. The next start behaves like a first run: the welcome tour appears and the first four presets are added.
