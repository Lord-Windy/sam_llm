local M = {}

local defaults = {
  model = "something",
  endpoint = "something"
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

local function sam_llm_debug(text) 
  vim.notify(text, vim.log.levels.DEBUG)
end

function M.process(text)
  sam_llm_debug(text)
end

return M
