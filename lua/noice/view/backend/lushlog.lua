-- LushNvim noice backend: append messages to a log file.
--
-- noice resolves a view's backend with require("noice.view.backend.<name>"),
-- so shipping this module in LushNvim's own lua/ tree makes "lushlog" a
-- regular view. It exists to capture errors that scroll off the screen or are
-- lost when the session ends — in particular Lua errors raised from async
-- callbacks (promise-async's UnhandledPromiseRejection, luv/vim.schedule
-- errors) which bypass vim.notify and only ever surface as emsg output.
--
-- Wired up in after/plugin/noice.lua when autocommands.error_log is enabled;
-- read the result with :LushErrors.

local View = require("noice.view")

---@class LushLogView: NoiceView
---@field super NoiceView
---@diagnostic disable-next-line: undefined-field
local LushLogView = View:extend("LushLogView")

local defaults = {
  path = vim.fn.stdpath("state") .. "/lush-errors.log",
}

function LushLogView:init(opts)
  LushLogView.super.init(self, opts)
end

function LushLogView:update_options()
  self._opts = vim.tbl_deep_extend("force", defaults, self._opts)
end

function LushLogView:show()
  local fp = io.open(self._opts.path, "a")
  if fp then
    local stamp = os.date("%Y-%m-%d %H:%M:%S")
    for _, m in ipairs(self._messages) do
      local text = vim.trim(m:content())
      if text ~= "" then
        fp:write(string.format("[%s] %s/%s\n%s\n\n", stamp, m.event, m.kind or "", text))
      end
    end
    fp:close()
  end
  self:clear()
end

function LushLogView:hide() end

return LushLogView
