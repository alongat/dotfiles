-- Line length warnings (MD013) are noise for prose, so lint with a base config that turns them off
return {
  "mfussenegger/nvim-lint",
  opts = {
    linters = {
      ["markdownlint-cli2"] = {
        prepend_args = { "--config", vim.fn.stdpath("config") .. "/.markdownlint.yaml" },
      },
    },
  },
}
