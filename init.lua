-- Bootstrap lazy
-- ------------------------------------------------------------
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.g.astronvim_first_install = true -- lets AstroNvim know that this is an initial installation
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

-- Setup Lazy:
-- ------------------------------------------------------------
require("lazy").setup {
  defaults = { lazy = true },
  lockfile = vim.fn.stdpath "state" .. "/lazy-lock.json",
  spec = {
    { "AstroNvim/AstroNvim", branch = "main", import = "astronvim.plugins" },

    -- Extended file type support
    { "sheerun/vim-polyglot", lazy = false },

    -- Community plugins:
    { "AstroNvim/astrocommunity", branch = "main" },
    { import = "astrocommunity.pack.bash" },
    { import = "astrocommunity.pack.cmake" },
    { import = "astrocommunity.pack.cpp" },
    { import = "astrocommunity.pack.json" },
    { import = "astrocommunity.pack.lua" },
    { import = "astrocommunity.pack.markdown" },
    { import = "astrocommunity.pack.python" },
    { import = "astrocommunity.pack.rust" },
    { import = "astrocommunity.pack.toml" },
    { import = "astrocommunity.pack.typescript" },
    { import = "astrocommunity.pack.yaml" },

    { import = "astrocommunity.diagnostics.trouble-nvim" },
    { import = "astrocommunity.git.octo-nvim" },
    { import = "astrocommunity.motion.flash-nvim" },
    { import = "astrocommunity.motion.nvim-surround" },

    -- OVERRIDE AstronVim plugins:
    { "nvim-treesitter/nvim-treesitter",
      config= function(_, opts)
        opts.ensure_installed = {}
        opts.auto_install = false
        opts.ignore_install = "all"
        return opts
      end,
    },
    { "max397574/better-escape.nvim", enabled = false },
    { "folke/snacks.nvim", enabled = false },
    { "nvim-telescope/telescope-fzf-native.nvim", enabled = false }, -- fails to build due to missing build tools
    {
      "L3MON4D3/LuaSnip",
      config = function(_, opts)
        require("luasnip").setup(opts)
        require("luasnip.loaders.from_vscode").lazy_load { paths = { vim.fn.stdpath "config" .. "/snippets" } } -- Not needed on windows!
      end,
    },
    -- force enable nvim-dap on windows
    { "mfussenegger/nvim-dap", enabled = true },
    -- override LSP config:
    {
      "AstroNvim/astrolsp",
      opts = {
        features = { inlay_hints = true },
        config = {
          rust_analyzer = {
            settings = {
              ["rust-analyzer"] = {
                cargo = {
                  buildScripts = { enable = true },
                  extraEnv = { CARGO_PROFILE_RUST_ANALYZER_INHERITS = "dev" },
                  extraArgs = { "--profile", "rust-analyzer" },
                },
                procMacro = { enable = true },
              },
            },
          },
        },
        formatting = {
          -- control auto formatting on save
          format_on_save = {
            -- enable or disable format on save globally
            enabled = false,
          },
          -- default format timeout
          timeout_ms = 10000,
        },
      },
    },
    {
      "nvim-telescope/telescope.nvim",
      opts = {
        defaults = {
          layout_strategy = "vertical",
          layout_config = {
            vertical = {
              prompt_position = "top",
              mirror = true,
              preview_cutoff = 40,
              preview_height = 0.5,
            },
            width = 0.95,
            height = 0.95,
          },
        },
        pickers = {
          current_buffer_tags = { fname_width = 100 },
          jumplist = { fname_width = 100 },
          loclist = { fname_width = 100 },
          lsp_definitions = { fname_width = 100 },
          lsp_document_symbols = { fname_width = 100 },
          lsp_dynamic_workspace_symbols = { fname_width = 100 },
          lsp_implementations = { fname_width = 100 },
          lsp_incoming_calls = { fname_width = 100 },
          lsp_outgoing_calls = { fname_width = 100 },
          lsp_references = { fname_width = 100 },
          lsp_type_definitions = { fname_width = 100 },
          lsp_workspace_symbols = { fname_width = 100, symbol_width = 50 },
          quickfix = { fname_width = 100 },
          tags = { fname_width = 100 },
        },
      },
    },
    -- override heirline config
    {
      "rebelot/heirline.nvim",
      -- Disable mappings for tabline
      dependencies = { "AstroNvim/astrocore" },
      -- Customize UI
      opts = function(_, orig)
        local status = require "astroui.status"

        return {
          opts = orig.opts,
          statusline = { -- statusline
            hl = { fg = "fg", bg = "bg" },
            status.component.mode(),
            status.component.git_branch(),
            status.component.fill(),
            status.component.cmd_info(),
            status.component.fill(),
            status.component.lsp(),
            status.component.virtual_env(),
            status.component.treesitter(),
            status.component.nav { scrollbar = false, percentage = false },
            status.component.mode { surround = { separator = "right" } },
          },
          winbar = { -- winbar
            init = function(self) self.bufnr = vim.api.nvim_get_current_buf() end,
            fallthrough = false,
            -- inactive winbar
            {
              condition = function() return not status.condition.is_active() end,
              -- show the path to the file relative to the working directory
              status.component.separated_path(),
              -- add the file name and icon
              status.component.file_info {
                file_icon = { hl = status.hl.file_icon "winbar", padding = { left = 0 } },
                filename = { modify = ":p:." },
                filetype = false,
                file_modified = false,
                file_read_only = false,
                hl = status.hl.get_attributes("winbarnc", true),
                surround = false,
                update = "BufEnter",
              },
            },
            -- active winbar
            {
              -- show the path to the file relative to the working directory
              status.component.separated_path(),
              -- add the file name and icon
              status.component.file_info { -- add file_info to breadcrumbs
                file_icon = { hl = status.hl.filetype_color, padding = { left = 0 } },
                filename = { modify = ":p:." },
                filetype = false,
                file_modified = false,
                file_read_only = false,
                hl = status.hl.get_attributes("winbar", true),
                surround = false,
                update = "BufEnter",
              },
              -- show the breadcrumbs
              status.component.breadcrumbs {
                icon = { hl = true },
                hl = status.hl.get_attributes("winbar", true),
                prefix = true,
                padding = { left = 0 },
              },
              status.component.fill(),
              status.component.git_diff(),
              status.component.diagnostics(),
            },
          },
          tabline = {},
          statuscolumn = orig.statuscolumn,
        }
      end,
    },
  },
}

-- polish:
-- ------------------------------------------------------------

-- override LSP inlay hints
vim.api.nvim_set_hl(0, "Comment", { fg = "#575d66", italic = false })
vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#575d66", italic = true })

-- Register slint filetype for *.slint files
vim.api.nvim_create_augroup("slint_auto", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = "slint_auto",
  pattern = "*.slint",
  callback = function() vim.bo.filetype = "slint" end,
})

-- set vim options here (vim.<first_key>.<second_key> = value)
vim.opt.clipboard = ""
vim.opt.colorcolumn = "80,100"
vim.opt.foldcolumn = "0" -- no folding marks
vim.opt.numberwidth = 4
vim.opt.scrolloff = 10
vim.opt.showtabline = 0 -- force tab line to off
vim.opt.sidescrolloff = 20
vim.opt.spell = true -- sets vim.opt.spell
vim.opt.timeoutlen = 1000 -- I'm a slow typist!
vim.opt.undofile = false

vim.g.markdown_fenced_languages = { "ts=typescript" }

-- Prettify LSP logs:
require("vim.lsp").set_log_level "OFF"
-- require("vim.lsp").set_log_level("TRACE")
require("vim.lsp.log").set_format_func(vim.inspect)

require("slint").setup()
