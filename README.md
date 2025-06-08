# sam_llm

Responses from the API are appended to a log file located at
`<nvim stdpath('cache')>/sam_llm.log` for debugging purposes.

When `LlmProcess` runs the current buffer is backed up to
`<nvim stdpath('cache')>/sam_lua/<date>` with a filename based on the
original buffer name and a timestamp. The extracted response can be backed up
in the same location. These backups are controlled with the
`backup_original` and `backup_response` configuration options.

