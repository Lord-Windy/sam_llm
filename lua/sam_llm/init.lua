local M = {}

local defaults = {
  model = "something",
  endpoint = "something",
  api_key = nil,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  if not M.config.api_key then
    M.config.api_key = os.getenv("ANTHROPIC_API_KEY")
  end
end

local function sam_llm_debug(text) 
  vim.notify(text, vim.log.levels.DEBUG)
end

function M.process(text)
  sam_llm_debug(text)
end

return M
