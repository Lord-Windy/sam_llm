local M = {}

local defaults = {
  model = "claude-opus-4-0",
  endpoint = "https://api.anthropic.com/v1/messages",
  api_key = "",
  backup_original = true,
  backup_response = true,
}

local function sam_llm_debug(text)
  vim.notify(text, vim.log.levels.DEBUG)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  if M.config.api_key == "" then
    M.config.api_key = os.getenv("ANTHROPIC_API_KEY")
  end
end

local log_file = vim.fn.stdpath("cache") .. "/sam_llm.log"

local cache_root = vim.fn.stdpath("cache") .. "/sam_lua"

local function ensure_dir(dir)
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

local function append_log(text)
  local f = io.open(log_file, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. text .. "\n")
    f:close()
  end
end

local function generate_comment_processing_json(content)

  local payload = "Please read the markdown file below and fill in all sections marked with << >>. Replace each << >> section with appropriate content based on the context. Return the complete markdown file with all << >> sections filled in. Do not add any additional commentary, explanations, or text outside of the markdown file itself. \n\n" .. content

  local message_data = {
    model = M.config.model,
    thinking = {
      type = "enabled",
      budget_tokens = 4096
    },
    system =
    "You are a world class writer. You are my assistant and your job is to help me write documentation and prose were appropriate.",
    max_tokens = 16000,
    messages = {
      {
        role = "user",
        content = payload
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

  -- create backup of the original buffer when enabled
  if M.config.backup_original then
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local basename = vim.fn.fnamemodify(bufname, ":t")
    local day = os.date("%Y-%m-%d")
    local timestamp = os.date("%Y-%m-%dT%H-%M-%S")
    local dir = cache_root .. "/" .. day
    ensure_dir(dir)
    local outfile = string.format("%s/%s-%s.orig", dir, basename, timestamp)
    vim.fn.writefile(lines, outfile)
  end

  -- create payload for Anthropic Claude
  local payload = generate_comment_processing_json(text)

  -- send the payload using curl
  local cmd = {
    "curl",
    "-s",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "-H",
    "anthropic-version: 2023-06-01",
    "-H",
    "x-api-key: " .. M.config.api_key,
    "-d",
    payload,
    M.config.endpoint,
  }

  local result = vim.fn.system(cmd)
  append_log(result)

  local ok, decoded = pcall(vim.json.decode, result)
  if not ok then
    sam_llm_debug("Error decoding response: " .. decoded)
    return
  end

  local collected = {}
  if decoded and decoded.content and type(decoded.content) == "table" then
    for _, item in ipairs(decoded.content) do
      if item.type == "text" and item.text then
        table.insert(collected, item.text)
      end
    end
  end

  local new_text = table.concat(collected, "\n")
  local new_lines = vim.split(new_text, "\n")

  if M.config.backup_response then
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local basename = vim.fn.fnamemodify(bufname, ":t")
    local day = os.date("%Y-%m-%d")
    local timestamp = os.date("%Y-%m-%dT%H-%M-%S")
    local dir = cache_root .. "/" .. day
    ensure_dir(dir)
    local outfile = string.format("%s/%s-%s.response", dir, basename, timestamp)
    vim.fn.writefile(new_lines, outfile)
  end

  -- replace the buffer with the new content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

return M
