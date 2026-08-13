-- Minecraft (Forge / Fabric / NeoForge) Java dev layer for LazyVim.
--
-- How this is meant to run (see /etc/nixos/modules/devshells/modules/java.nix):
--   * Launch `nvim` from inside the project's nix devshell. In this repo that's
--     `direnv` + `.envrc` -> `use flake …/devshells#mc_1_20_1`, which puts
--     `jdtls`, JDK17 and JDK21 on PATH and exports JAVA_HOME_17 / JAVA_HOME_21.
--   * jdtls itself runs on JDK21 (recent jdtls dropped JDK17), while the project
--     is *compiled* against JavaSE-17 and Gradle / runClient keep JDK17 via
--     JAVA_HOME. Those three never collide — see the cmd + runtimes below.
--   * Every loader (Forge/Fabric/NeoForge) is Gradle, so `:OverseerRun`
--     (<leader>mr) is the IntelliJ-style run/build menu for runClient etc.

local uv = vim.uv or vim.loop

-- $JAVA_HOME_<ver> from the devshell, if it points at a real directory.
local function jdk_home(ver)
  local home = vim.env["JAVA_HOME_" .. ver]
  if home and uv.fs_stat(home) then
    return home
  end
  return nil
end

-- vscode-java debug/test bundles from the devshell ($JDTLS_BUNDLES_DIR). jdtls
-- loads these via init_options.bundles; without them nvim-dap's
-- `vscode.java.startDebugSession` and the test runner silently no-op. Absent
-- (nvim started outside the devshell) => DAP degrades to attach-only.
local function java_debug_bundles()
  local dir = vim.env.JDTLS_BUNDLES_DIR
  if not dir or not uv.fs_stat(dir) then
    return nil
  end
  local jars = vim.fn.glob(dir .. "/*/server/*.jar", false, true)
  return #jars > 0 and jars or nil
end

-- ── nvim-dap for Java (jdtls debug adapter + test runner) ──────────────────
-- LazyVim's java extra only calls setup_dap() when *mason* provides the
-- java-debug-adapter; on Nix the bundles come from the devshell instead, so
-- wire it here. setup_dap() is idempotent (no-ops if dap.adapters.java exists).
-- Main-class discovery is fetched once per session — it's slow on big
-- Forge/Fabric classpaths. `<F5>` (LazyVim core) then offers the discovered
-- configs; Forge runClient itself has no main() you can start from jdtls, so
-- for MC use "Debug (Attach) - Remote" (:5005) against a runClient started
-- with a JDWP agent (add to build.gradle:
--   tasks.named('runClient') { jvmArgs '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005' }
-- or grab it via the `runclientdebug` snippet).
local dap_wired = false
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "jdtls" then
      return
    end
    local ok_dap, dap = pcall(require, "dap")
    local ok_jdtls, jdtls = pcall(require, "jdtls")
    if not ok_dap or not ok_jdtls then
      return
    end
    if not dap_wired then
      dap_wired = true
      jdtls.setup_dap({ hotcodereplace = "auto", config_overrides = {} })
      jdtls.dap.setup_dap_main_class_configs({ verbose = false })
    end
    -- Java test runner (LazyVim only adds these when its mason bundles exist).
    require("which-key").add({
      {
        mode = "n",
        buffer = args.buf,
        { "<leader>tt", function() jdtls.dap.test_class({ config_overrides = {} }) end, desc = "Run Tests (class)" },
        { "<leader>tr", function() jdtls.dap.test_nearest_method({ config_overrides = {} }) end, desc = "Run Nearest Test" },
        { "<leader>tT", jdtls.dap.pick_test, desc = "Pick Test" },
      },
    })
  end,
})

-- Nearest Gradle project root (works for Forge / Fabric / NeoForge).
local function gradle_root()
  local start = vim.fn.expand("%:p:h")
  if start == "" then
    start = vim.fn.getcwd()
  end
  local found = vim.fs.find({ "gradlew" }, { upward = true, path = start })[1]
  return found and vim.fs.dirname(found) or vim.fn.getcwd()
end

-- Fire a `./gradlew <args>` task through Overseer at the Gradle root.
local function run_gradle(args)
  require("overseer")
    .new_task({
      name = "gradlew " .. table.concat(args, " "),
      cmd = { "./gradlew" },
      args = args,
      cwd = gradle_root(),
      components = { "default" },
    })
    :start()
  vim.cmd("OverseerOpen")
end

return {
  --------------------------------------------------------------------------
  -- 1. jdtls: point LazyVim's nvim-jdtls at the nix toolchain + MC settings
  --------------------------------------------------------------------------
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local jdtls = vim.fn.exepath("jdtls")
      if jdtls == "" then
        vim.schedule(function()
          vim.notify(
            "jdtls not on PATH — start nvim from the project's nix devshell "
              .. "(`direnv allow`, or `nix develop …/devshells#mc_1_20_1`) so the "
              .. "Java LSP can launch.",
            vim.log.levels.WARN,
            { title = "Minecraft / Java" }
          )
        end)
        return opts
      end

      local jdk17 = jdk_home("17")
      local jdk21 = jdk_home("21") or vim.env.JAVA_HOME

      -- Launch command. Force jdtls onto JDK21 explicitly so the shell's
      -- JAVA_HOME=JDK17 (Gradle / Forge / runClient) is never touched.
      local cmd = { jdtls }
      if jdk21 then
        vim.list_extend(cmd, { "--java-executable", jdk21 .. "/bin/java" })
      end
      -- Minecraft + decompiled sources are a large index — give jdtls room.
      vim.list_extend(cmd, {
        "--jvm-arg=-XX:+UseParallelGC",
        "--jvm-arg=-XX:GCTimeRatio=4",
        "--jvm-arg=-XX:AdaptiveSizePolicyWeight=90",
        "--jvm-arg=-Dsun.zip.disableMemoryMapping=true",
        "--jvm-arg=-Xms256m",
        "--jvm-arg=-Xmx2G",
      })
      -- Optional Lombok javaagent from the devshell (harmless if unused by MC).
      local lombok = vim.env.LOMBOK_JAR
      if lombok and uv.fs_stat(lombok) then
        table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok)
      end
      opts.cmd = cmd

      -- Tell jdtls which JDKs exist. Forge 1.20.1's Gradle toolchain declares
      -- JavaSE-17, so jdtls compiles against 17 while running on 21.
      local runtimes = {}
      if jdk17 then
        table.insert(runtimes, { name = "JavaSE-17", path = jdk17, default = true })
      end
      if jdk21 then
        table.insert(runtimes, { name = "JavaSE-21", path = jdk21 })
      end

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          configuration = {
            updateBuildConfiguration = "interactive",
            runtimes = runtimes,
          },
          import = {
            gradle = {
              enabled = true,
              -- Honour ./gradlew: Forge/Fabric pin their Gradle version.
              wrapper = { enabled = true },
            },
          },
          -- Read the decompiled Minecraft sources Gradle produces.
          eclipse = { downloadSources = true },
          maven = { downloadSources = true },
          references = { includeDecompiledSources = true },
          implementationsCodeLens = { enabled = true },
          referencesCodeLens = { enabled = true },
          symbols = { includeSourceMethodDeclarations = true },
          contentProvider = { preferred = "fernflower" },
          -- Big project: don't recompile the world on every keystroke.
          autobuild = { enabled = false },
          completion = {
            importOrder = { "java", "javax", "com", "net", "org" },
          },
          signatureHelp = { enabled = true },
          inlayHints = { parameterNames = { enabled = "all" } },
        },
      })

      -- Feed the java-debug/test bundles into the jdtls server. LazyVim deep-
      -- merges `opts.jdtls` into the init_options it builds at attach time.
      local bundles = java_debug_bundles()
      if bundles then
        opts.jdtls = { init_options = { bundles = bundles } }
      else
        vim.schedule(function()
          vim.notify(
            "JDTLS_BUNDLES_DIR unset — nvim-dap / java-test bundles won't load. "
              .. "Start nvim from the project devshell (direnv / nix develop).",
            vim.log.levels.WARN,
            { title = "Minecraft / Java" }
          )
        end)
      end
      opts.dap = { hotcodereplace = "auto", config_overrides = {} }
      opts.dap_main = {}
      opts.test = true

      return opts
    end,
  },

  --------------------------------------------------------------------------
  -- 2. Overseer: IntelliJ-style run/build menu for Gradle & Forge tasks
  --------------------------------------------------------------------------
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerRun",
      "OverseerToggle",
      "OverseerOpen",
      "OverseerRunCmd",
      "OverseerQuickAction",
    },
    opts = {
      strategy = "terminal",
      task_list = { direction = "bottom", min_height = 15, bindings = { ["q"] = "<cmd>close<cr>" } },
    },
    config = function(_, opts)
      local overseer = require("overseer")
      overseer.setup(opts)

      -- Curated tasks. Not every task exists in every loader; Gradle simply
      -- errors if you pick one that doesn't apply, which is fine.
      local tasks = {
        { "Forge/NeoForge: runClient", { "runClient" }, "Boot the modded client" },
        { "Forge/NeoForge: runServer", { "runServer" }, "Boot a dedicated server" },
        { "Forge/NeoForge: runData", { "runData" }, "Run data generators" },
        { "Fabric: genSources", { "genSources" }, "Decompile MC sources (Loom)" },
        { "Gradle: build", { "build" }, "Full build" },
        { "Gradle: jar", { "jar" }, "Build the mod jar" },
        { "Gradle: clean", { "clean" }, "Clean outputs" },
        { "Gradle: genEclipseRuns", { "genEclipseRuns" }, "Regenerate run configs" },
        { "Gradle: genIntellijRuns", { "genIntellijRuns" }, "Regenerate run configs" },
        { "Gradle: refresh deps", { "--refresh-dependencies" }, "Re-resolve dependencies" },
      }

      for _, t in ipairs(tasks) do
        local name, args, desc = t[1], t[2], t[3]
        overseer.register_template({
          name = name,
          desc = desc,
          tags = { "MINECRAFT" },
          condition = {
            callback = function()
              return vim.fn.filereadable(gradle_root() .. "/gradlew") == 1
            end,
          },
          builder = function()
            return {
              cmd = { "./gradlew" },
              args = args,
              cwd = gradle_root(),
              components = { "default" },
            }
          end,
        })
      end
    end,
    keys = {
      { "<leader>mr", "<cmd>OverseerRun<cr>", desc = "Run Gradle/Forge task" },
      { "<leader>mt", "<cmd>OverseerToggle<cr>", desc = "Toggle task list" },
      { "<leader>mq", "<cmd>OverseerQuickAction<cr>", desc = "Task quick action" },
      { "<leader>mc", function() run_gradle({ "runClient" }) end, desc = "runClient" },
      { "<leader>ms", function() run_gradle({ "runServer" }) end, desc = "runServer" },
      { "<leader>mb", function() run_gradle({ "build" }) end, desc = "build" },
      { "<leader>mg", function() run_gradle({ "genSources" }) end, desc = "genSources (Fabric)" },
    },
  },

  --------------------------------------------------------------------------
  -- 3. which-key group label for the <leader>m Minecraft menu
  --------------------------------------------------------------------------
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>m", group = "minecraft/gradle", icon = "" },
      },
    },
  },
}
