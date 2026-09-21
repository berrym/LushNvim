local utils = require("config.utils")
local group = utils.get_plugin_group()

-- project.nvim (v6) stores history as JSON in project_history.json under
-- <stdpath('data')>/project_nvim. There is no in-plugin migration command for
-- the pre-v4 plain-text `project_history` file; if one is left over, delete it
-- and re-add projects, or rebuild the list with `:Project import`.
--
-- Config is read-only from the outside now: `require("project.config").get()`
-- returns the resolved options table (the old `.options` field is gone).

if utils.enabled(group, "project") then
  require("project").setup({
    -- Detection patterns: covers all common project types
    patterns = {
      ".git",
      -- Build systems
      "Makefile",
      "CMakeLists.txt",
      "meson.build",
      -- Rust
      "Cargo.toml",
      -- Python
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
      "Pipfile",
      -- Go
      "go.mod",
      -- JavaScript/TypeScript
      "package.json",
      "tsconfig.json",
      -- Java
      "pom.xml",
      "build.gradle",
      "build.gradle.kts",
      -- Ruby
      "Gemfile",
      -- Zig
      "build.zig",
      -- Perl
      "cpanfile",
      "Makefile.PL",
      -- Docker
      "docker-compose.yml",
      "docker-compose.yaml",
      -- General
      ".editorconfig",
    },
    -- Don't auto-chdir; autocommands.lua handles CWD management
    enable_autochdir = false,
    silent_chdir = true,
    exclude_dirs = { vim.fn.expand("~") },
  })
end
