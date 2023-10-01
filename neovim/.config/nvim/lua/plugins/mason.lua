return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "prisma-language-server",
        "lua-language-server",
        "typescript-language-server",
        "flake8",
      },
    },
  },
}
