local utils = require("config.utils")
local group = utils.get_plugin_group()

if utils.enabled(group, "project") then
	require("project_nvim").setup({
		-- Detection patterns: covers all common project types
		patterns = {
			".git",
			-- Build systems
			"Makefile", "CMakeLists.txt", "meson.build",
			-- Rust
			"Cargo.toml",
			-- Python
			"pyproject.toml", "setup.py", "setup.cfg", "Pipfile",
			-- Go
			"go.mod",
			-- JavaScript/TypeScript
			"package.json", "tsconfig.json",
			-- Java
			"pom.xml", "build.gradle", "build.gradle.kts",
			-- Ruby
			"Gemfile",
			-- Zig
			"build.zig",
			-- Perl
			"cpanfile", "Makefile.PL",
			-- Docker
			"docker-compose.yml", "docker-compose.yaml",
			-- General
			".editorconfig",
		},
		-- Don't auto-chdir; autocommands.lua handles CWD management
		enable_autochdir = false,
		silent_chdir = true,
		exclude_dirs = { vim.fn.expand("~") },
	})
end
