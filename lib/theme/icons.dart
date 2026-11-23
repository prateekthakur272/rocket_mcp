import 'package:material_ui/material_ui.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// One place that names every icon the app uses: the rounded Material icons, so the whole interface shares one
/// visual style (the same set DevSpace uses). Pick the icon by meaning (`Ic.tool`, `Ic.resource`, `Ic.prompt` for MCP
/// primitives) and add new ones here rather than using `Icons` directly in a widget. [Ico] draws them.
class Ic {
  Ic._();
  static const IconData logo = Icons.rocket_launch_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData timer = Icons.timer_rounded;
  static const IconData speed = Icons.speed_rounded;
  static const IconData checklist = Icons.checklist_rounded;
  static const IconData more = Icons.more_horiz_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData collapseAll = Icons.unfold_less_rounded;
  static const IconData up = Icons.keyboard_arrow_up_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData chevronLeft = Icons.chevron_left_rounded;
  static const IconData docs = Icons.menu_book_rounded;
  static const IconData down = Icons.keyboard_arrow_down_rounded;
  static const IconData dropDown = Icons.keyboard_arrow_down_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData cancel = Icons.cancel_rounded;
  static const IconData skip = Icons.skip_next_rounded;
  static const IconData folder = Icons.folder_rounded;
  static const IconData folderOpen = Icons.folder_open_rounded;
  static const IconData attach = Icons.attach_file_rounded;
  static const IconData text = Icons.text_fields_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData copy = Icons.content_copy_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData upload = Icons.upload_rounded;
  static const IconData save = Icons.save_rounded;
  static const IconData code = Icons.code_rounded;
  static const IconData send = Icons.send_rounded;
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData workflow = Icons.account_tree_rounded;
  static const IconData stop = Icons.stop_rounded;
  static const IconData settings = Icons.settings_rounded;

  /// A server's configuration (its connection settings): the `{}` glyph.
  static const IconData configuration = Icons.data_object_rounded;
  static const IconData light = Icons.light_mode_rounded;
  static const IconData dark = Icons.dark_mode_rounded;
  static const IconData cookie = Icons.cookie_rounded;
  static const IconData variables = Icons.data_object_rounded;
  static const IconData environments = Icons.layers_rounded;
  static const IconData sidebar = Icons.view_sidebar_rounded;
  static const IconData splitV = Icons.vertical_split_rounded;
  static const IconData splitH = Icons.horizontal_split_rounded;
  static const IconData compare = Icons.compare_arrows_rounded;
  static const IconData bulb = Icons.lightbulb_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData rename = Icons.drive_file_rename_outline_rounded;
  static const IconData clone = Icons.file_copy_rounded;
  static const IconData open = Icons.open_in_new_rounded;
  static const IconData newFile = Icons.note_add_rounded;
  static const IconData newFolder = Icons.create_new_folder_rounded;
  static const IconData export = Icons.file_upload_rounded;
  static const IconData import = Icons.input_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData command = Icons.keyboard_command_key_rounded;
  static const IconData bolt = Icons.bolt_rounded;
  static const IconData moveUp = Icons.arrow_upward_rounded;
  static const IconData moveDown = Icons.arrow_downward_rounded;
  static const IconData reveal = Icons.folder_open_rounded;
  static const IconData tab = Icons.tab_rounded;
  static const IconData link = Icons.link_rounded;
  static const IconData drag = Icons.drag_indicator_rounded;
  static const IconData person = Icons.person_rounded;
  static const IconData shield = Icons.shield_rounded;
  static const IconData tune = Icons.tune_rounded;
  static const IconData bug = Icons.bug_report_rounded;
  static const IconData lock = Icons.lock_rounded;
  static const IconData eye = Icons.visibility_rounded;
  static const IconData eyeOff = Icons.visibility_off_rounded;
  static const IconData fingerprint = Icons.fingerprint_rounded;
  static const IconData info = Icons.info_rounded;
  static const IconData codec = Icons.transform_rounded;
  static const IconData noBody = Icons.block_rounded;
  static const IconData formBody = Icons.dynamic_form_rounded;
  static const IconData graph = Icons.hub_rounded;
  static const IconData http = Icons.language_rounded;
  static const IconData websocket = Icons.swap_horiz_rounded;
  static const IconData grpc = Icons.lan_rounded;
  static const IconData fmtJson = Icons.data_object_rounded;
  static const IconData fmtHtml = Icons.html_rounded;
  static const IconData fmtXml = Icons.data_array_rounded;
  static const IconData fmtJs = Icons.javascript_rounded;
  static const IconData fmtRaw = Icons.notes_rounded;
  static const IconData fmtHex = Icons.tag_rounded;
  static const IconData fmtB64 = Icons.password_rounded;
  static const IconData wrap = Icons.wrap_text_rounded;
  static const IconData expandAll = Icons.unfold_more_rounded;
  static const IconData fileGeneric = Icons.insert_drive_file_rounded;
  static const IconData pdf = Icons.picture_as_pdf_rounded;
  static const IconData audio = Icons.audiotrack_rounded;
  static const IconData video = Icons.movie_rounded;
  static const IconData image = Icons.image_rounded;
  static const IconData key = Icons.key_rounded;
  static const IconData dash = Icons.remove_rounded;
  static const IconData git = Icons.alt_route_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData apps = Icons.apps_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData arrowOut = Icons.north_east_rounded;
  static const IconData tool = Icons.build_rounded;
  static const IconData resource = Icons.dataset_rounded;
  static const IconData prompt = Icons.chat_bubble_rounded;
  static const IconData resourceTemplate = Icons.data_array_rounded;
  static const IconData server = Icons.dns_rounded;
  static const IconData stdio = Icons.terminal_rounded;
  static const IconData sse = Icons.sensors_rounded;
  static const IconData streamHttp = Icons.cloud_sync_rounded;
  static const IconData subscribe = Icons.notifications_active_rounded;
  static const IconData ping = Icons.network_ping_rounded;
  static const IconData presets = Icons.bookmarks_rounded;
  static const IconData connecting = Icons.sync_rounded;
  static const IconData connect = Icons.power_rounded;
  static const IconData disconnect = Icons.power_off_rounded;
  static const IconData outgoing = Icons.north_east_rounded;
  static const IconData incoming = Icons.south_west_rounded;
  static const IconData readResource = Icons.find_in_page_rounded;
  static const IconData traffic = Icons.swap_vert_rounded;
  static const IconData windowMinimize = Icons.remove_rounded;
  static const IconData windowMaximize = Icons.crop_square_rounded;
  static const IconData windowRestore = Icons.filter_none_rounded;
  static const IconData windowClose = Icons.close_rounded;

  /// The GitHub mark (not in the Material set): a sentinel [IconData] that [Ico] draws from the 24x24 outline.
  static const IconData gitHub = IconData(
    0xF0001,
    fontFamily: '__RocketMcpGitHub',
  );
}

const _githubPath =
    'M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12';

/// Minimal SVG path-data parser (M/L/H/V/C/S/Q/T/Z, absolute and relative; no arcs).
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = RegExp(
    r'[MmLlHhVvCcSsQqTtZz]|-?(?:\d+\.?\d*|\.\d+)(?:e[-+]?\d+)?',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cmd = '';
  double x = 0, y = 0, sx = 0, sy = 0, cx = 0, cy = 0;
  var lastCmd = '';
  double next() => double.parse(tokens[i++]);
  bool isNum() =>
      i < tokens.length && !RegExp(r'^[A-Za-z]$').hasMatch(tokens[i]);
  while (i < tokens.length) {
    if (!isNum()) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    switch (cmd.toUpperCase()) {
      case 'Z':
        path.close();
        x = sx;
        y = sy;
        break;
      case 'M':
        var nx = next(), ny = next();
        if (rel) {
          nx += x;
          ny += y;
        }
        path.moveTo(nx, ny);
        x = nx;
        y = ny;
        sx = nx;
        sy = ny;
        cmd = rel ? 'l' : 'L';
        break;
      case 'L':
        var nx = next(), ny = next();
        if (rel) {
          nx += x;
          ny += y;
        }
        path.lineTo(nx, ny);
        x = nx;
        y = ny;
        break;
      case 'H':
        var nx = next();
        if (rel) nx += x;
        path.lineTo(nx, y);
        x = nx;
        break;
      case 'V':
        var ny = next();
        if (rel) ny += y;
        path.lineTo(x, ny);
        y = ny;
        break;
      case 'C':
        var x1 = next(),
            y1 = next(),
            x2 = next(),
            y2 = next(),
            nx = next(),
            ny = next();
        if (rel) {
          x1 += x;
          y1 += y;
          x2 += x;
          y2 += y;
          nx += x;
          ny += y;
        }
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
        break;
      case 'S':
        var x2 = next(), y2 = next(), nx = next(), ny = next();
        if (rel) {
          x2 += x;
          y2 += y;
          nx += x;
          ny += y;
        }
        final c = lastCmd == 'C' || lastCmd == 'S';
        final x1 = c ? 2 * x - cx : x, y1 = c ? 2 * y - cy : y;
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
        break;
      case 'Q':
        var x1 = next(), y1 = next(), nx = next(), ny = next();
        if (rel) {
          x1 += x;
          y1 += y;
          nx += x;
          ny += y;
        }
        path.quadraticBezierTo(x1, y1, nx, ny);
        cx = x1;
        cy = y1;
        x = nx;
        y = ny;
        break;
      case 'T':
        var nx = next(), ny = next();
        if (rel) {
          nx += x;
          ny += y;
        }
        final c = lastCmd == 'Q' || lastCmd == 'T';
        final x1 = c ? 2 * x - cx : x, y1 = c ? 2 * y - cy : y;
        path.quadraticBezierTo(x1, y1, nx, ny);
        cx = x1;
        cy = y1;
        x = nx;
        y = ny;
        break;
    }
    lastCmd = cmd.toUpperCase();
  }
  return path;
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.path, this.color, this.vb);
  final Path path;
  final Color color;
  final double vb;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / vb, size.height / vb);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.color != color;
}

final Path _githubParsed = parseSvgPath(_githubPath);

/// A tinted icon of fixed [size] (default tint: the palette's muted colour).
class Ico extends StatelessWidget {
  const Ico(
    this.icon, {
    super.key,
    this.tint,
    this.size = 16,
    this.withBg = false,
  });

  final IconData icon;
  final Color? tint;
  final double size;
  final bool withBg;

  @override
  Widget build(BuildContext context) {
    final c = tint ?? context.pal.muted;
    if (icon == Ic.logo) {
      final assetPath = withBg
          ? 'assets/app_icon.png'
          : 'assets/app_icon_nobg.png';
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: withBg
              ? BorderRadius.circular(size * 0.22)
              : BorderRadius.zero,
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(Ic.logo, size: size, color: c),
            ),
          ),
        ),
      );
    }
    if (icon == Ic.gitHub) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PathPainter(_githubParsed, c, 24)),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(icon, size: size, color: c),
      ),
    );
  }
}
