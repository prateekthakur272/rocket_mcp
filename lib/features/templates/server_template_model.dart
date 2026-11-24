import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:rocket_mcp/core/mcp/model.dart';

/// Categories of MCP server templates in the gallery.
enum ServerTemplateCategory {
  all('All', Icons.apps_rounded),
  reference('Reference & Test', Icons.science_rounded),
  databases('Databases & Storage', Icons.storage_rounded),
  devTools('Developer Tools', Icons.terminal_rounded),
  web('Web & Automation', Icons.language_rounded),
  productivity('Productivity & Cloud', Icons.cloud_queue_rounded);

  const ServerTemplateCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// A curated MCP server template in the Template Gallery.
class ServerTemplate {
  const ServerTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.config,
    this.icon,
    this.author = 'Official',
    this.package,
    this.tags = const [],
    this.featured = false,
  });

  final String id;
  final String name;
  final ServerTemplateCategory category;
  final String description;
  final McpServerConfig config;
  final IconData? icon;
  final String author;
  final String? package;
  final List<String> tags;
  final bool featured;

  String get commandPreview {
    if (config.transport == McpTransportType.sse ||
        config.transport == McpTransportType.streamHttp) {
      return config.url;
    }
    final cmd = config.command;
    final args = config.args.join(' ');
    return '$cmd $args'.trim();
  }
}

/// Catalog of pre-configured official and community MCP server templates.
final class ServerTemplates {
  const ServerTemplates._();

  static final List<ServerTemplate> all = [
    // --- Reference & Testing ---
    const ServerTemplate(
      id: 'template_everything',
      name: 'Everything Server',
      category: ServerTemplateCategory.reference,
      description: 'Official reference server demonstrating all MCP capabilities: parameterized tools, dynamic resources, prompt templates, and notifications.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-everything',
      icon: Icons.auto_awesome_rounded,
      featured: true,
      tags: ['reference', 'tools', 'resources', 'prompts', 'stdio'],
      config: McpServerConfig(
        id: 'template_everything',
        name: 'Everything Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-everything'],
      ),
    ),
    const ServerTemplate(
      id: 'template_memory',
      name: 'Memory Knowledge Graph',
      category: ServerTemplateCategory.reference,
      description: 'Graph-based persistent memory system. Models entities, relations, observations, and structural semantic knowledge.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-memory',
      icon: Icons.hub_rounded,
      featured: true,
      tags: ['memory', 'knowledge-graph', 'state', 'stdio'],
      config: McpServerConfig(
        id: 'template_memory',
        name: 'Memory Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-memory'],
      ),
    ),
    const ServerTemplate(
      id: 'template_stream_http',
      name: 'Streamable HTTP Endpoint',
      category: ServerTemplateCategory.reference,
      description: 'Sample remote HTTP endpoint with chunked responses, streaming protocol support, and real-time payload traffic.',
      author: 'Rocket MCP',
      icon: Icons.http_rounded,
      tags: ['http', 'stream', 'remote', 'testing'],
      config: McpServerConfig(
        id: 'template_stream_http',
        name: 'Streamable HTTP Server',
        transport: McpTransportType.streamHttp,
        url: 'http://localhost:8000/mcp',
        headers: {'Accept': 'application/json, text/event-stream'},
      ),
    ),
    const ServerTemplate(
      id: 'template_sse_local',
      name: 'Local SSE Server',
      category: ServerTemplateCategory.reference,
      description: 'Server-Sent Events (SSE) remote transport connection for testing asynchronous push and duplex notifications.',
      author: 'Rocket MCP',
      icon: Icons.cell_tower_rounded,
      tags: ['sse', 'events', 'streaming', 'remote'],
      config: McpServerConfig(
        id: 'template_sse_local',
        name: 'Local SSE Server',
        transport: McpTransportType.sse,
        url: 'http://localhost:3001/sse',
      ),
    ),

    // --- Databases & Storage ---
    const ServerTemplate(
      id: 'template_filesystem',
      name: 'Local Filesystem',
      category: ServerTemplateCategory.databases,
      description: 'Read, write, list, and search files and directories within specified allowed directory paths.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-filesystem',
      icon: Icons.folder_open_rounded,
      featured: true,
      tags: ['files', 'disk', 'search', 'stdio'],
      config: McpServerConfig(
        id: 'template_filesystem',
        name: 'Filesystem Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-filesystem', '.'],
      ),
    ),
    const ServerTemplate(
      id: 'template_sqlite',
      name: 'SQLite Database',
      category: ServerTemplateCategory.databases,
      description: 'Query SQLite databases, inspect table schemas, analyze table metrics, run read-only or read-write statements.',
      author: 'Community',
      package: 'mcp-server-sqlite',
      icon: Icons.storage_rounded,
      featured: true,
      tags: ['sqlite', 'sql', 'database', 'uvx'],
      config: McpServerConfig(
        id: 'template_sqlite',
        name: 'SQLite Server',
        transport: McpTransportType.stdio,
        command: 'uvx',
        args: ['mcp-server-sqlite', '--db-path', 'test.db'],
      ),
    ),
    const ServerTemplate(
      id: 'template_postgres',
      name: 'PostgreSQL Database',
      category: ServerTemplateCategory.databases,
      description: 'Inspect PostgreSQL database tables, run read queries, explore schema definitions, and analyze database structure.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-postgres',
      icon: Icons.dns_rounded,
      tags: ['postgres', 'sql', 'database', 'stdio'],
      config: McpServerConfig(
        id: 'template_postgres',
        name: 'PostgreSQL Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: [
          '-y',
          '@modelcontextprotocol/server-postgres',
          'postgresql://localhost/mydb',
        ],
      ),
    ),
    const ServerTemplate(
      id: 'template_redis',
      name: 'Redis Store',
      category: ServerTemplateCategory.databases,
      description: 'Key-value and data structure manipulation on local or remote Redis servers: inspect keys, get values, and manage cache.',
      author: 'Community',
      package: 'mcp-server-redis',
      icon: Icons.dataset_rounded,
      tags: ['redis', 'cache', 'key-value', 'uvx'],
      config: McpServerConfig(
        id: 'template_redis',
        name: 'Redis Server',
        transport: McpTransportType.stdio,
        command: 'uvx',
        args: ['mcp-server-redis', 'redis://localhost:6379'],
      ),
    ),

    // --- Developer Tools ---
    const ServerTemplate(
      id: 'template_git',
      name: 'Git Repository',
      category: ServerTemplateCategory.devTools,
      description: 'Inspect local Git repositories, read commit logs, generate diffs, inspect branch states, and search repository history.',
      author: 'Community',
      package: 'mcp-server-git',
      icon: Icons.commit_rounded,
      featured: true,
      tags: ['git', 'version-control', 'diff', 'uvx'],
      config: McpServerConfig(
        id: 'template_git',
        name: 'Git Server',
        transport: McpTransportType.stdio,
        command: 'uvx',
        args: ['mcp-server-git', '--repository', '.'],
      ),
    ),
    const ServerTemplate(
      id: 'template_github',
      name: 'GitHub API',
      category: ServerTemplateCategory.devTools,
      description: 'Manage pull requests, issues, commits, branches, repository files, and code search on GitHub.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-github',
      icon: Icons.code_rounded,
      featured: true,
      tags: ['github', 'vcs', 'issues', 'pr', 'stdio'],
      config: McpServerConfig(
        id: 'template_github',
        name: 'GitHub Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-github'],
        env: {'GITHUB_PERSONAL_ACCESS_TOKEN': '<token>'},
      ),
    ),
    const ServerTemplate(
      id: 'template_gitlab',
      name: 'GitLab API',
      category: ServerTemplateCategory.devTools,
      description: 'GitLab project integration: manage merge requests, issue tracking, CI pipelines, and repository files.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-gitlab',
      icon: Icons.source_rounded,
      tags: ['gitlab', 'vcs', 'ci', 'stdio'],
      config: McpServerConfig(
        id: 'template_gitlab',
        name: 'GitLab Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-gitlab'],
        env: {'GITLAB_PERSONAL_ACCESS_TOKEN': '<token>'},
      ),
    ),
    const ServerTemplate(
      id: 'template_docker',
      name: 'Docker Engine',
      category: ServerTemplateCategory.devTools,
      description: 'Interact with local Docker daemon: list containers, tail logs, start/stop services, and inspect images.',
      author: 'Docker Inc.',
      icon: Icons.layers_rounded,
      tags: ['docker', 'containers', 'daemon', 'stdio'],
      config: McpServerConfig(
        id: 'template_docker',
        name: 'Docker Server',
        transport: McpTransportType.stdio,
        command: 'docker',
        args: [
          'run',
          '-i',
          '--rm',
          '-v',
          '/var/run/docker.sock:/var/run/docker.sock',
          'mcp/docker',
        ],
      ),
    ),

    // --- Web & Automation ---
    const ServerTemplate(
      id: 'template_fetch',
      name: 'Fetch & Markdown',
      category: ServerTemplateCategory.web,
      description: 'Download web pages, scrape web content, and convert raw HTML into clean, readable Markdown documents.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-fetch',
      icon: Icons.public_rounded,
      featured: true,
      tags: ['web', 'scrape', 'markdown', 'stdio'],
      config: McpServerConfig(
        id: 'template_fetch',
        name: 'Fetch Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-fetch'],
      ),
    ),
    const ServerTemplate(
      id: 'template_brave_search',
      name: 'Brave Web Search',
      category: ServerTemplateCategory.web,
      description: 'Live internet search engine integration: search query results, local business search, and fresh web information.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-brave-search',
      icon: Icons.travel_explore_rounded,
      tags: ['search', 'brave', 'web', 'stdio'],
      config: McpServerConfig(
        id: 'template_brave_search',
        name: 'Brave Search',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-brave-search'],
        env: {'BRAVE_API_KEY': '<api-key>'},
      ),
    ),
    const ServerTemplate(
      id: 'template_puppeteer',
      name: 'Puppeteer Browser',
      category: ServerTemplateCategory.web,
      description: 'Automate headless Chrome: open web pages, capture full screenshots, evaluate JavaScript, and interact with web UI.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-puppeteer',
      icon: Icons.web_rounded,
      tags: ['browser', 'chrome', 'screenshot', 'automation'],
      config: McpServerConfig(
        id: 'template_puppeteer',
        name: 'Puppeteer Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-puppeteer'],
      ),
    ),

    // --- Productivity & Cloud ---
    const ServerTemplate(
      id: 'template_slack',
      name: 'Slack Workspace',
      category: ServerTemplateCategory.productivity,
      description: 'Send messages, list team channels, reply in threads, and search message archives inside Slack.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-slack',
      icon: Icons.chat_rounded,
      tags: ['slack', 'chat', 'messaging', 'stdio'],
      config: McpServerConfig(
        id: 'template_slack',
        name: 'Slack Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-slack'],
        env: {'SLACK_BOT_TOKEN': 'xoxb-...', 'SLACK_TEAM_ID': 'T...'},
      ),
    ),
    const ServerTemplate(
      id: 'template_gdrive',
      name: 'Google Drive',
      category: ServerTemplateCategory.productivity,
      description: 'Access Google Drive files: list, search, and read documents, spreadsheets, and drive contents.',
      author: 'Anthropic / MCP',
      package: '@modelcontextprotocol/server-gdrive',
      icon: Icons.add_to_drive_rounded,
      tags: ['gdrive', 'docs', 'cloud', 'stdio'],
      config: McpServerConfig(
        id: 'template_gdrive',
        name: 'Google Drive Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-gdrive'],
      ),
    ),
    const ServerTemplate(
      id: 'template_sentry',
      name: 'Sentry Issues',
      category: ServerTemplateCategory.productivity,
      description: 'Search Sentry error reports, inspect stack traces, query unresolved crashes, and analyze release health.',
      author: 'Sentry / Community',
      package: 'mcp-server-sentry',
      icon: Icons.bug_report_rounded,
      tags: ['sentry', 'errors', 'monitoring', 'uvx'],
      config: McpServerConfig(
        id: 'template_sentry',
        name: 'Sentry Server',
        transport: McpTransportType.stdio,
        command: 'uvx',
        args: ['mcp-server-sentry'],
        env: {'SENTRY_AUTH_TOKEN': '<token>'},
      ),
    ),
    const ServerTemplate(
      id: 'template_cloudflare',
      name: 'Cloudflare Platform',
      category: ServerTemplateCategory.productivity,
      description: 'Manage Cloudflare Workers, KV key-value stores, D1 SQL databases, and DNS zones directly through MCP tools.',
      author: 'Cloudflare',
      package: '@cloudflare/mcp-server-cloudflare',
      icon: Icons.cloud_done_rounded,
      tags: ['cloudflare', 'workers', 'serverless', 'stdio'],
      config: McpServerConfig(
        id: 'template_cloudflare',
        name: 'Cloudflare Server',
        transport: McpTransportType.stdio,
        command: 'npx',
        args: ['-y', '@cloudflare/mcp-server-cloudflare'],
        env: {'CLOUDFLARE_API_TOKEN': '<token>'},
      ),
    ),
  ];
}
