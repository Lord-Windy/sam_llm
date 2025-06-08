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

local log_file = vim.fn.stdpath("cache") .. "/sam_llm.log"

local function append_log(text)
  local f = io.open(log_file, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. text .. "\n")
    f:close()
  end
end

function M.process(_)
  -- grab the entire contents of the current buffer
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, "\n")

  -- echo the buffer text for debugging
  sam_llm_debug(text)

  -- create payload for Anthropic Claude
  local payload = {
    model = M.config.model,
    prompt = table.concat({
      "Please read the comments in the following file and return the file ",
      "with those comments edited and completed. Comments that you need to fill out ",
      "are surrounded by << >>. Anything else you are to read as context but do not change.",
      "You are an assistant helping me make my markdown documents better:\n\n",
      text,
    }, " "),
  }

  -- send the payload using curl
  local cmd = {
    "curl",
    "-s",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "-H",
    "x-api-key: " .. M.config.api_key,
    "-d",
    vim.fn.json_encode(payload),
    M.config.endpoint,
  }
  local result = vim.fn.system(cmd)
  append_log(result)
end

return M

