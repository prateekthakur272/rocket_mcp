# Troubleshooting

## Where Rocket MCP keeps its files

`~/.rocketmcp` (Windows: `%USERPROFILE%\.rocketmcp`). **Help ▸ Open Storage Folder** or **⌘⇧O** opens it. See [data and storage](data-and-storage.md). The file `rocketmcp.log` there records warnings and errors and is the best thing to attach to a bug report. Look through it first: it can contain server names and file paths.

To start fresh, quit the app and move the folder, or use **Preferences ▸ Data ▸ Reset preferences** for settings only.

## Connecting

- **"Could not connect" for a stdio server.** Read the message. The most common cause is that the command is not found: Rocket MCP starts it with your normal `PATH`, so `npx`, `uvx` or `node` must be installed and reachable. When the app is started from a launcher rather than a terminal it can have a shorter `PATH` than your shell; use the full path to the executable in **Command** if so.
- **The process starts but never answers.** Check **Server Logs** (it shows the process's standard error). Many servers print the reason there. Make sure the server really speaks MCP on standard input and output and prints nothing else to standard output.
- **First run is slow.** `npx -y …` downloads the package the first time; give it a minute, or run the command in a terminal once.
- **SSE or streamable HTTP will not connect.** Check the URL and any headers (an `Authorization` header is a common need). Try the URL in a browser or with `curl`. Certificate errors on a local server can be avoided by turning off **Preferences ▸ Network ▸ Verify SSL certificates**.
- **Connected, but the lists are empty.** The server may not offer tools, resources or prompts, or may not have advertised them. The **Traffic Inspector** shows exactly what was asked and answered. **⌘⇧R** fetches everything again.

## Tools

- **Run does nothing and a warning button appeared.** A required argument is empty, or the JSON body is invalid. Click the warning button; it lists what to fix and jumps to the field.
- **"Arguments must be a JSON object".** In JSON mode the body must be `{ … }`, not an array or a plain value.
- **A number is sent as text.** Make sure the schema says `number` or `integer`. A field whose schema says `string` always sends text.
- **The result looks empty.** Switch the view menu: **Formatted** shows only the tool's text content; **Raw JSON** shows the whole answer, including structured content and any error.

## The app

- **Nothing happens when I press a shortcut.** On Windows and Linux use Ctrl where this documentation says ⌘. If a text field has focus, the field may keep some keys; press Esc first.
- **The window opens off-screen after unplugging a monitor.** Rocket MCP ignores a saved position that is no longer on any screen. If it still misbehaves, delete `window.json`.
- **The text is too small or large.** **⌘+ / ⌘−**, or **Preferences ▸ Appearance ▸ Interface size**; **⌘0** resets it.
- **Updates.** If the check says it could not reach GitHub, you are offline or rate-limited; try again later.

If none of this helps, press the bug icon in the status bar to open a pre-filled report.
