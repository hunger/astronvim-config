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
    { "AstroNvim/AstroNvim", branch = "v4", import = "astronvim.plugins" },

    -- Extended file type support
    { "sheerun/vim-polyglot", lazy = false },

    -- Community plugins:
    { "AstroNvim/astrocommunity", branch = "v4" },
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
    { import = "astrocommunity.motion.leap-nvim" },
    { import = "astrocommunity.motion.nvim-surround" },

    -- use modern inlay hints:
    {
      "p00f/clangd_extensions.nvim",
      optional = true,
      opts = { extensions = { autoSetHints = false } },
    },
    {
      "simrat39/rust-tools.nvim",
      optional = true,
      opts = { tools = { inlay_hints = { auto = false } } },
    },

    -- OVERRIDE AstronVim plugins:
    { "max397574/better-escape.nvim", enabled = false },
    { "goolord/alpha-nvim", enabled = false },
    -- {
    --   "L3MON4D3/LuaSnip",
    --   config = function(plugin, opts)
    --     require("plugins.configs.luasnip")(plugin, opts)
    --     require("luasnip.loaders.from_vscode").lazy_load { paths = { "/home/extra/.config/nvim-data/snippets" } } -- Not needed on windows!
    --   end,
    -- },
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
            -- enable format on save for specified filetypes only
            allow_filetypes = {
              "rust",
            },
          },
          -- disable formatting capabilities for specific language servers
          disabled = {
            "null_ls",
          },
          -- default format timeout
          timeout_ms = 10000,
        },
      },
    },
    {
      "hrsh7th/nvim-cmp",
      opts = function(_, opts)
        local cmp = require "cmp"
        local compare = require "cmp.config.compare"
        local luasnip = require "luasnip"

        local function has_words_before()
          local line, col = unpack(vim.api.nvim_win_get_cursor(0))
          return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
        end

        return require("astrocore").extend_tbl(opts, {
          window = { completion = { col_offset = -1, side_padding = 0 } },
          sorting = {
            comparators = {
              compare.offset,
              compare.exact,
              compare.score,
              compare.recently_used,
              function(entry1, entry2)
                local _, entry1_under = entry1.completion_item.label:find "^_+"
                local _, entry2_under = entry2.completion_item.label:find "^_+"
                entry1_under = entry1_under or 0
                entry2_under = entry2_under or 0
                if entry1_under > entry2_under then
                  return false
                elseif entry1_under < entry2_under then
                  return true
                end
              end,
              compare.kind,
              compare.sort_text,
              compare.length,
              compare.order,
            },
          },
          mapping = {
            -- tab complete
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() and has_words_before() then
                cmp.confirm { select = true }
              else
                fallback()
              end
            end, { "i", "s" }),
            -- <C-n> and <C-p> for navigating snippets
            ["<C-n>"] = cmp.mapping(function()
              if luasnip.jumpable(1) then luasnip.jump(1) end
            end, { "i", "s" }),
            ["<C-p>"] = cmp.mapping(function()
              if luasnip.jumpable(-1) then luasnip.jump(-1) end
            end, { "i", "s" }),
            -- <C-j> for starting completion
            ["<C-j>"] = cmp.mapping(function()
              if cmp.visible() then
                cmp.select_next_item { behavior = cmp.SelectBehavior.Insert }
              else
                cmp.complete()
              end
            end, { "i", "s" }),
          },
        })
      end,
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
      opts = function(_, opts)
        local components = require "astroui.status.component"

        opts.statusline = {
          hl = { fg = "fg", bg = "bg" },
          components.mode(),
          components.git_branch(),
          components.git_diff(),
          components.fill(),
          components.lsp(),
          components.treesitter(),
          components.nav { scrollbar = false, percentage = false, padding = { left = 1 } },
          components.mode { surround = { separator = "right" } },
        }
        opts.winbar = {
          hl = { fg = "fg", bg = "bg" },
          components.file_info { filename = { modify = ":p:." } },
          components.breadcrumbs { icon = { hl = true }, padding = { left = 1 } },
          components.fill(),
          components.diagnostics(),
        }

        return opts
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
vim.opt.showtabline = 0 -- force tab line to off
vim.opt.spell = true -- sets vim.opt.spell
vim.opt.timeoutlen = 1000 -- I'm a slow typist!
vim.opt.undofile = false

vim.g.markdown_fenced_languages = { "ts=typescript" }

-- Prettify LSP logs:
require("vim.lsp").set_log_level "OFF"
-- require("vim.lsp").set_log_level("TRACE")
require("vim.lsp.log").set_format_func(vim.inspect)

require("slint").setup()
