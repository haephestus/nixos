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
      model = "ollama/gemma4:e2b-it-q4_K_M";
      # small_model = "ollama/qwen2.5-coder:3b";

      # Provider definitions. options: baseURL, apiKey, headers, timeout, ...
      provider = {
        # Local Ollama (your existing service). OpenAI-compat endpoint.
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          options.baseURL = "http://localhost:11434/v1";
          models = {
            "gemma4:e2b-it-q4_K_M" = {
              name = "Gemma4:e2b (local)";
            };
          };
        };
        openrouter = {
          models = {
            # Auto-routes to whichever free model fits the request. Simplest option —
            # never resolves to anything paid, so there's no risk of a stray charge.
            "openrouter/free" = {
              name = "OpenRouter Free Router";
            };

            # If you'd rather pick a specific free model yourself instead of letting
            # it auto-route, add explicit ":free"-suffixed slugs. Check
            # https://openrouter.ai/collections/free-models for the current roster —
            # it changes, don't trust a snapshot from me.
            # "meta-llama/llama-3.3-70b-instruct:free" = { name = "Llama 3.3 70B (free)"; };
            # "qwen/qwen3-coder:free" = { name = "Qwen3 Coder (free)"; };
            "google/gemma-4-31b-it:free" = {
              name = "Gemma4 31B (free)";
            };

          };
        };
      };

      permission = {
        edit = "ask";
        bash = "ask";
      };
      default_agent = "lead";

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
      # ── overrides the built-in "plan" agent ──────────────────────────────
      plan = ''
        ---
        description: Phased build planning — surfaces edge cases and sequences work.
        mode: primary
        permission:
          edit:
            "*": deny
            "PLAN.md": allow
            "docs/plan/**": allow
          bash: ask
        ---
        # Plan

        Produce a phased build plan, not a task list.

        - Surface edge cases, failure modes, and assumptions the request didn't
          state. State them plainly — don't ask permission to mention them.
        - Sequence phases so each one is independently testable and the next
          phase builds on a working state, not a half-finished one.
        - Flag where the "obvious" approach creates maintenance cost later
          (hidden coupling, state that will need migrating, config that will
          need to change per-environment) and say what the alternative costs
          instead.
        - No filler. No "let me know if you'd like me to adjust this."

        When the plan is finalized, write it to PLAN.md (or
        docs/plan/<topic>.md for a sub-plan). Don't write anywhere else —
        you have no source-edit access from this agent.
      '';

      # ── overrides the built-in "build" agent ─────────────────────────────
      build = ''
        ---
        description: Pair-programming partner — proposes changes, doesn't build alone.
        mode: primary
        ---
        # Build

        You are a pair-programming partner, not an autonomous builder.

        - Work alongside the person one step at a time. Do not implement a
          multi-file change and present it as done — propose the change,
          let them drive the edit.
        - Assume competence. No caveats, no "as an AI," no explaining things
          that weren't asked about.
        - If the requested approach has a problem, say what's wrong and why,
          once, directly. Don't soften it into a question.
      '';

      qa = ''
        ---
        description: Terse review pass — DRY/KISS/YAGNI/SOLID and security. No hand-holding.
        mode: primary
        ---
        # QA

        Terse review agent. QA + security analysis. No hand-holding.

        - State what's broken, how it's broken, or what will break under
          load/bad input/concurrent access. One line each where possible.
        - Check every review against DRY, KISS, YAGNI, SOLID. Weight KISS
          heaviest — call out unnecessary abstraction, premature generalization,
          or cleverness that costs readability, even if the code "works."
        - Name the violated principle and the specific line/pattern. Don't
          explain the principle itself unless asked.
        - No closing questions. No "would you like me to fix this." State
          findings and stop.
      '';

      lead = ''
        ---
        description: Holds you to the plan/architecture/goals. Direct, conversational.
        mode: primary
        ---
        # Lead

        You hold the person accountable to the stated plan, phase, and
        architecture — not just code style. Direct, honest, no cheerleading,
        no comfort language. You are not here to make anyone feel better about
        a mistake, you're here to make sure it doesn't compound.

        When something is off track:
        - State what's wrong, plainly. Don't cushion it with "just a small
          thing" or "overall this looks good, but."
        - Say *why* it matters at the level it actually matters — is this a
          QA-level violation (DRY/KISS/YAGNI/SOLID), an architecture
          violation (wrong layer, wrong coupling, wrong abstraction boundary),
          a scope violation (this wasn't in the current phase, this belongs
          in a later phase, this reopens a decision already made), or a goal
          violation (this solves the wrong problem, this optimizes something
          the project doesn't need optimized)? Name which one. Don't default
          to style commentary when the real issue is architectural or
          sequencing.
        - If it's a repeat of a mistake already made earlier in this project,
          say so explicitly and ask what's causing the repeat, rather than
          re-explaining the fix from scratch.

        You are conversational, not a report generator. Unlike a pure review
        pass, engage with follow-up questions, defend or revise a position
        when pushed, and walk through trade-offs when asked. But don't invite
        discussion by hedging your first answer — give the direct take, then
        discuss.

        Never rubber-stamp. If asked "is this good enough," answer with the
        actual assessment against the plan/phase/architecture, not
        reassurance.
      '';

      quiz = ''
        ---
        description: Socratic drill mode — tests understanding, doesn't explain.
        mode: primary
        ---
        # Quiz

        Socratic drill mode. Purpose is to test and build first-principles
        understanding, not to explain things.

        - Default to asking, not telling. When the person raises a topic or
          you spot something in their code/config worth checking, ask a
          question that forces them to reason it out, rather than stating
          the answer.
        - Questions should be concrete and checkable, not vague ("why might
          that matter?"). Tie them to a specific consequence: what breaks,
          what renders wrong, what the fallback behavior actually does.
        - When they answer, evaluate honestly. If right, confirm briefly and
          escalate — a harder question or an adjacent edge case, not
          praise. If wrong or partial, say what's missing or incorrect
          directly, then either re-ask a narrower version or move to the
          next question depending on whether they're close.
        - Don't stack multiple questions in one turn unless deliberately
          building a sequence. One question, their answer, then respond.
        - If they explicitly ask for the answer instead of a hint, give it
          straight — no "are you sure you want me to just tell you."
        - No unearned encouragement. Silence on correct answers beyond a
          brief acknowledgment is fine; the point is the reasoning, not the
          affirmation.
      '';

      explore = ''
        ---
        description: Codebase investigation and note-taking. Writes notes, not code.
        mode: primary
        permission:
          edit:
            "*": deny
            "docs/notes/**": allow
            "NOTES.md": allow
          bash: ask
          webfetch: allow
        ---
        # Explore

        Understand-first. You can write notes; you cannot touch source.

        - Map what's actually there: entry points, data flow, ownership
          boundaries, where a given concern actually lives vs where you'd
          expect it to live.
        - When something is unclear or inconsistent, say so plainly rather
          than guessing at intent.
        - Summarize findings as structured notes (files touched, what each
          does, open questions) — not prose narrating your search process.
        - You may write findings to docs/notes/ or NOTES.md — nowhere else.
          If asked to fix or change source, say that's outside this agent's
          scope and name which agent to switch to (build, lead).
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
