# home-manager/opencode.nix
#
# Declarative opencode config — managed via home-manager's `programs.opencode`
# module. This file mirrors the full option tree from
# https://home-manager.dev/manual/unstable/options/home-manager/programs/opencode.html
#
# Every option is present below for documentation. Unused options are commented
# out; only `enable` and the values you actually use are active.
#
# File mapping (written when the corresponding option is non-default):
#   settings → ~/.config/opencode/opencode.json
#   tui      → ~/.config/opencode/tui.json
#   context  → ~/.config/opencode/AGENTS.md
#   agents   → ~/.config/opencode/agents/<name>.md
#   commands → ~/.config/opencode/commands/<name>.md
#   skills   → ~/.config/opencode/skills/<name>/SKILL.md
#   themes   → ~/.config/opencode/themes/<name>.json
#   tools    → ~/.config/opencode/tools/<name>.ts
#
# ⚠️ Do NOT put API keys here — they'd land in the world-readable Nix store.
# Authenticate providers out-of-band: `opencode auth login`, or use
# `{env:VAR}` / `{file:path}` substitution inside `settings`.
{
  pkgs,
  ...
}:
let
  # waybarrios/opencode-power-pack — a curated skill pack (code-review, security,
  # Hugging Face, …). Pinned to a specific commit; `nix-prefetch-git`/`nix flake
  # prefetch` prints the hash if you ever need to bump it.
  power-pack = pkgs.fetchFromGitHub {
    owner = "waybarrios";
    repo = "opencode-power-pack";
    rev = "def4641869c821d3a2fd23cc3ad248f56759354a";
    sha256 = "sha256-rHpKfX7BjXtz2nsS9vwz5IAhyqB0X9OmMjbya5qKQaY=";
  };
  skillPath = name: "${power-pack}/skills/${name}";
in
{
  programs.opencode = {
    # ── programs.opencode.enable ─────────────────────────────────────────────
    # type: boolean   default: false
    # Whether to enable opencode. Installs pkgs.opencode and writes configs.
    enable = true;

    # ── programs.opencode.enableMcpIntegration ───────────────────────────────
    # type: boolean   default: false
    # If true, merges config.programs.mcp.servers (home-manager MCP servers)
    # into settings.mcp, with OpenCode settings taking precedence.
    # enableMcpIntegration = false;

    # ── programs.opencode.package ────────────────────────────────────────────
    # type: null or package   default: pkgs.opencode
    # Override the opencode package.
    # package = pkgs.opencode;

    # ── programs.opencode.extraPackages ──────────────────────────────────────
    # type: list of package   default: [ ]
    # Extra packages put on opencode's PATH (available to agents/tools/bash).
    extraPackages = with pkgs; [
      # pkgs.uv pkgs.jq pkgs.gh
      lsof
    ];

    # ── programs.opencode.settings ───────────────────────────────────────────
    # type: JSON value   default: { }
    # Written to opencode.json. "$schema" is added automatically.
    # Docs: https://opencode.ai/docs/config/
    settings = {
      # Default model; small_model is used for cheap tasks like title gen.
      model = "ollama/qwen2.5-coder:3b";
      # small_model = "ollama/qwen2.5-coder:3b";

      # Provider definitions. options: baseURL, apiKey, headers, timeout, ...
      provider = {
        # Local Ollama (your existing service). OpenAI-compat endpoint.
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          options.baseURL = "http://localhost:11434/v1";
          models = {
            "qwen2.5-coder:3b" = {
              name = "Qwen2.5 Coder 3B (local)";
            };
          };
        };
        # openrouter = { # key via env/`opencode auth`, NOT here
        #   models = { "deepseek/deepseek-chat" = { name = "DeepSeek (cheap)"; }; };
        # };
      };

      permission = {
        edit = "ask";
        bash = "ask";
      };
      default_agent = "mentor";

      # -- other settings (reference) --
      # server = { port = 4096; hostname = "0.0.0.0"; mdns = true; cors = [ ]; };
      # shell = "/bin/zsh";
      # tools = { write = false; bash = false; };
      # agent = { "code-reviewer" = { description = "..."; model = "..."; prompt = "..."; }; };
      # subagent_depth = 1;
      # share = "manual";          # "manual" | "auto" | "disabled"
      # autoupdate = true;         # true | false | "notify"
      # command = { test = { template = "..."; description = "..."; }; };
      # formatter = true;          # or object w/ per-formatter config
      # lsp = true;                # or object w/ per-server config
      # compaction = { auto = true; prune = false; reserved = 10000; };
      # watcher = { ignore = [ "node_modules/**" ".git/**" ]; };
      # mcp = { "my-server" = { type = "local"; command = [ "npx" "-y" "@.../server-foo" ]; enabled = true; }; };
      # plugin = [ "opencode-helicone-session" ];
      # instructions = [ "CONTRIBUTING.md" "docs/guidelines.md" ];
      # snapshot = true;
      # disabled_providers = [ "openai" "gemini" ];
      # enabled_providers = [ "anthropic" "openai" ];
      # attachment = { image = { auto_resize = true; max_width = 2000; max_height = 2000; max_base64_bytes = 5242880; }; };
      # experimental = { policies = [ { effect = "deny"; action = "provider.use"; resource = "openai"; } ]; };
    };

    # ── programs.opencode.tui ────────────────────────────────────────────────
    # type: JSON value   default: { }
    # Written to tui.json. "$schema" is added automatically.
    # Since opencode v1.2.15, theme/keybinds live HERE, not in settings.
    # Docs: https://opencode.ai/docs/tui/#configure
    tui = {
      # Built-in themes, or a custom theme from programs.opencode.themes.
      theme = "tokyonight";

      # keybinds = { leader = "alt+b"; command_list = "ctrl+p"; };
      # scroll_speed = 3;
      # scroll_acceleration = { enabled = true; };
      # diff_style = "auto";                       # "auto" | "minimal" | "full"
      # cursor = { style = "block"; blinking = true; };
      # mouse = true;
      # attention = { enabled = true; notifications = true; sound = true; volume = 0.4; };
    };

    # ── programs.opencode.context ────────────────────────────────────────────
    # type: lines or path   default: ""
    # Global instructions → ~/.config/opencode/AGENTS.md.
    # context = ''
    #   # Global rules
    #   - Always read CONTRIBUTING.md before editing.
    # '';
    # context = ./dotfiles/opencode/AGENTS.md; # or a path to a file

    # ── programs.opencode.agents ─────────────────────────────────────────────
    # type: attrset of (lines or path) | path   default: { }
    # Custom agents → ~/.config/opencode/agents/<name>.md.
    agents = {
      mentor = ''
        # Mentor

        You are a senior engineer mentoring a developer who is building
        first-principles fluency, not outsourcing thinking.

        Rules:
        - Never write or edit files directly. If a fix is needed, explain the
          underlying principle first, then show the correction as a diff or
          snippet in your response, and let the person apply it themselves.
        - When reviewing code, call out logic errors, architectural
          weaknesses, and defensive-coding gaps explicitly, and explain *why*
          each one matters, not just what to change.
        - When something touches security, reason like a cyber analyst:
          trust boundaries, input validation, failure modes, blast radius.
        - Prefer questions that make the person reason it out, before handing
          over the answer outright.
      '';
      # "code-reviewer" = ''
      #   # Code Reviewer
      #   You are a senior engineer specializing in code reviews.
      # '';
      # documentation = ./dotfiles/opencode/agents/documentation.md;
    };
    # agents = ./dotfiles/opencode/agents; # or a directory (symlinked)

    # ── programs.opencode.commands ───────────────────────────────────────────
    # type: attrset of (lines or path) | path   default: { }
    # Custom commands → ~/.config/opencode/commands/<name>.md.
    # commands = {
    #   commit = ''
    #     # Commit
    #     Create a git commit with proper message formatting.
    #     Usage: /commit [message]
    #   '';
    # };
    # commands = ./dotfiles/opencode/commands; # or a directory (symlinked)

    # ── programs.opencode.skills ─────────────────────────────────────────────
    # type: attrset of (lines|path|string) | path   default: { }
    # Custom skills → ~/.config/opencode/skills/<name>/SKILL.md.
    # Accepts inline text, files, directories, or store paths.
    skills = {
      # -- code review / architecture mentorship --
      code-review = skillPath "code-review";
      code-reviewer = skillPath "code-reviewer";
      code-architect = skillPath "code-architect";
      code-explorer = skillPath "code-explorer";
      code-quality = skillPath "code-quality";
      design-patterns = skillPath "design-patterns";
      sharp-edges = skillPath "sharp-edges"; # language/runtime footguns
      fp-check = skillPath "fp-check"; # false-positive discipline in review
      ai-slop = skillPath "ai-slop"; # spotting low-quality generated code
      differential-review = skillPath "differential-review";

      # -- defensive coding / cyber analyst --
      security-review = skillPath "security-review";
      security-threat-model = skillPath "security-threat-model";
      insecure-defaults = skillPath "insecure-defaults";
      semgrep = skillPath "semgrep";
      semgrep-rule-creator = skillPath "semgrep-rule-creator";
      semgrep-rule-variant-creator = skillPath "semgrep-rule-variant-creator";
      codeql = skillPath "codeql";
      variant-analysis = skillPath "variant-analysis";
      sarif-parsing = skillPath "sarif-parsing";
      vuln-report = skillPath "vuln-report";
      supply-chain-risk-auditor = skillPath "supply-chain-risk-auditor";
      agentic-actions-auditor = skillPath "agentic-actions-auditor";

      # -- deep research --
      paper-summarizer = skillPath "paper-summarizer";

      # -- Hugging Face / Spaces --
      hf-cli = skillPath "hf-cli";
      huggingface-spaces = skillPath "huggingface-spaces";
      huggingface-gradio = skillPath "huggingface-gradio";
      huggingface-lora-space-builder = skillPath "huggingface-lora-space-builder";
      huggingface-zerogpu = skillPath "huggingface-zerogpu";
      huggingface-trackio = skillPath "huggingface-trackio";
      huggingface-local-models = skillPath "huggingface-local-models";

      # -- inline / path / directory forms (reference) --
      # git-release = ''
      #   ---
      #   name: git-release
      #   description: Create consistent releases and changelogs
      #   ---
      #   ## What I do
      #   - Draft release notes from merged PRs
      # '';
      # data-analysis = ./dotfiles/opencode/skills/data-analysis;
      # beads = "${pkgs.beads.src}/claude-plugin/skills/beads";
    };
    # skills = ./dotfiles/opencode/skills; # or a directory (symlinked)

    # ── programs.opencode.themes ─────────────────────────────────────────────
    # type: attrset of (JSON value or path) | path   default: { }
    # Custom themes → ~/.config/opencode/themes/<name>.json.
    # Enable one via programs.opencode.tui.theme.
    # themes = {
    #   mytheme = { primary = "#ffffff"; background = "#1a1b26"; };
    # };
    # themes = ./dotfiles/opencode/themes; # or a directory (symlinked)

    # ── programs.opencode.tools ──────────────────────────────────────────────
    # type: attrset of (lines or path) | path   default: { }
    # Custom TypeScript tools → ~/.config/opencode/tools/<name>.ts.
    # tools = {
    #   "database-query" = ''
    #     import { tool } from "@opencode-ai/plugin"
    #     export default tool({
    #       description: "Query the project database",
    #       args: { query: tool.schema.string().describe("SQL query") },
    #       async execute(args) { return `Executed query: ''${args.query}` },
    #     })
    #   '';
    #   "api-client" = ./dotfiles/opencode/tools/api-client.ts;
    # };
    # tools = ./dotfiles/opencode/tools; # or a directory (symlinked)

    # ── programs.opencode.web.enable ─────────────────────────────────────────
    # type: boolean   default: false
    # Whether to run `opencode serve` as a systemd user service.
    # web.enable = true;

    # ── programs.opencode.web.environmentFile ────────────────────────────────
    # type: null or path   default: null
    # KEY=VALUE file for the service env (e.g. OPENCODE_SERVER_PASSWORD)
    # WITHOUT leaking secrets into the Nix store.
    # web.environmentFile = "/run/secrets/opencode-web";

    # ── programs.opencode.web.extraArgs ──────────────────────────────────────
    # type: list of string   default: [ ]
    # Extra args to `opencode serve` (override server options in settings).
    # web.extraArgs = [ "--hostname" "0.0.0.0" "--port" "4096" ];
  };
}
