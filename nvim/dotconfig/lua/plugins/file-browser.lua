return {
  "nvim-telescope/telescope-file-browser.nvim",
  keys = {
    {
      "<leader>sB",
      ":Telescope file_browser path=%:p:h=%:p:h<cr>",
      desc = "Browse Files",
    },
  },
  config = function()
    require("telescope").load_extension("file_browser").setup({
      defaults = {
        file_ignore_patterns = {},
      },
      extensions = {
        file_browser = {
          hidden = true,
          show_hidden = true,
        },
      },
    })
  end,
  dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
}
