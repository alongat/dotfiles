return {
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-go", "nvim-neotest/neotest-plenary" },
    opts = function(_, opts)
      table.insert(opts.adapters, require("neotest-go"))
      table.insert(opts.adapters, require("neotest-plenary"))
    end,
  },
}
