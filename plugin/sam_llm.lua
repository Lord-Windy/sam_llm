local sam_llm = require("sam_llm")

sam_llm.setup(nil)

vim.api.nvim_create_user_command(
  "LlmProcess",                      -- :LlmProcess / :llmprocess / :llm_process
  function(opts)                     -- opts.args   -> entire arg string
    sam_llm.process(opts.args)
  end,
  {
    nargs = "*",                     -- 0 or more args after the command
    range = true,                     -- allow visual-selection or :'<,'>
    desc = "Send text to your LLM backend"
  }
)
