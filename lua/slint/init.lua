-- Slint LSP test related helpers:

local vim_lsp = require("vim.lsp")

local M = {
   slint_dev_lsp_id = nil,

  _slint_dev_attach_to_current_buffer = function()
    local M = require("slint")
    if M.slint_dev_lsp_id then
      if vim_lsp.get_client_by_id(M.slint_dev_lsp_id) then
        print "Already running!"
        return M.slint_dev_lsp_id
      else
        M.slint_dev_lsp_id = nil
      end
    end

    local lsp = require("astrolsp");

    local srv = lsp.config.servers["slint_lsp"] or {}
    srv.name = "dev-slint"
    srv.root_dir = vim.fn.expand "%:p:h"

    srv.cmd = { "/home/tobias/src/slint/target/debug/slint-lsp" }
    srv.cmd_cwd = srv.root_dir
    local on_init = srv.on_init

    M.slint_dev_lsp_id = nil
    vim_lsp.set_log_level "DEBUG"

    srv.on_init = function(client, result)
      M.slint_dev_lsp_id = client.id
      if on_init then
        on_init(client, result)
      end
      vim_lsp.buf_attach_client(0, M.slint_dev_lsp_id)
    end

    vim_lsp.start_client(srv)
  end,

  slint_dev_client = function()
    local M = require("slint")
    return vim_lsp.get_client_by_id(M.slint_dev_lsp_id)
  end,

  slint_dev_kill = function()
    local M = require("slint")
    if M.slint_dev_lsp_id then
      vim_lsp.buf_detach_client(0, M.slint_dev_lsp_id)
      vim_lsp.stop_client(M.slint_dev_lsp_id, true)
      M.slint_dev_lsp_id = nil
      vim_lsp.set_log_level "OFF"
    end
  end,

  slint_dev_execute = function(cmd, args)
    local M = require("slint")
    M.slint_dev_client().request("workspace/executeCommand", { command = cmd, arguments = args }, M.slint_dev_handler, 0)
  end,

  slint_dev_restart = function()
    local M = require("slint")
    M.slint_dev_kill()
    M._slint_dev_attach_to_current_buffer()
  end,

  slint_dev_notifier = function(e, r, ctx, c)
    vim.notify("Handled something!\n" .. vim.inspect { error = e, reply = r, context = ctx, config = c })
  end,

  setup = function()
    vim.api.nvim_create_user_command("SDAttach", function()
      local M = require("slint")
      M._slint_dev_attach_to_current_buffer()
    end, {})
    vim.api.nvim_create_user_command("SDRestart", function()
      local M = require("slint")
      M.slint_dev_restart()
    end, {})
    vim.api.nvim_create_user_command("SDKill", function()
      local M = require("slint")
      M.slint_dev_kill()
    end, {})
    vim.api.nvim_create_user_command(
      "SDExecDesignModeEnable",
      function()
        local M = require("slint")
        M.slint_dev_execute("slint/setDesignMode", { true })
      end,
      {}
    )
    vim.api.nvim_create_user_command(
      "SDExecDesignModeDisable",
      function()
        local M = require("slint")
        M.slint_dev_execute("slint/setDesignMode", { false })
      end,
      {}
    )
    vim.api.nvim_create_user_command(
      "SDExecShowPreview",
      function()
        local M = require("slint")
        local url = vim.uri_from_fname(vim.api.nvim_buf_get_name(0))
        M.slint_dev_execute("slint/showPreview", { url })
      end,
      {}
    )
  end
}

return M
