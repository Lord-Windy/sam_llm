local M = {}

local defaults = {
  model = "claude-sonnet-4-0",
  endpoint = "https://api.anthropic.com/v1/messages",
  api_key = "",
}

local function sam_llm_debug(text)
  vim.notify(text, vim.log.levels.DEBUG)
end

function M.setup(opts)
  sam_llm_debug("HELLO FROM SETUP")
  M.config = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  if M.config.api_key == "" then
    M.config.api_key = os.getenv("ANTHROPIC_API_KEY")
  end
end

local log_file = vim.fn.stdpath("cache") .. "/sam_llm.log"

local function append_log(text)
  local f = io.open(log_file, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. text .. "\n")
    f:close()
  end
end

--[[thinking = {
      type = "enabled",
      budget_tokens = 1000
    },
    system =
    "You are a world class writer. You are my assistant and your job is to help me write documentation and prose were appropriate. Please read the comments in this file, you can find them by looking for any << >> blocks. Once read replace the block with what is asked. You are not to edit or change text outside of those sections.",
    --]]

local function generate_comment_processing_json(content)
  local message_data = {
    model = M.config.model,
    max_tokens = 30000,
    messages = {
      {
        role = "user",
        content = content
      }
    }
  }

  return vim.json.encode(message_data)
end

function M.process(_)
  -- grab the entire contents of the current buffer
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, "\n")

  -- create payload for Anthropic Claude
  local payload = generate_comment_processing_json(text)

  append_log(payload)

  -- send the payload using curl
  local cmd = {
    "curl",
    --"-s",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "-H",
    "anthropic-version: 2023-06-01",
    "-H",
    "x-api-key: " .. M.config.api_key,
    "-d",
    vim.fn.json_encode(payload),
    M.config.endpoint,
  }

  append_log(vim.inspect(cmd))

  local result = vim.fn.system(cmd)
  append_log(result)
end

return M
