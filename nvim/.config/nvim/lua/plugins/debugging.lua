local capabilities = require("config.capabilities")
if not capabilities.enabled("debug") then
  return {}
end

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
    "jay-babu/mason-nvim-dap.nvim",
    "williamboman/mason.nvim",
    "nvim-neotest/nvim-nio",
  },
  cmd = {
    "DapContinue",
    "DapToggleBreakpoint",
    "DapStepOver",
    "DapStepInto",
    "DapStepOut",
  },
  keys = {
    { "<leader>dc", function() require("dap").continue() end, desc = "Debug continue" },
    {
      "<leader>db",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "Debug breakpoint",
    },
    { "<leader>dn", function() require("dap").step_over() end, desc = "Debug step over" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Debug step into" },
    { "<leader>do", function() require("dap").step_out() end, desc = "Debug step out" },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    dapui.setup()
    require("nvim-dap-virtual-text").setup()

    dap.listeners.before.attach.dapui_config = dapui.open
    dap.listeners.before.launch.dapui_config = dapui.open
    dap.listeners.before.event_terminated.dapui_config = dapui.close
    dap.listeners.before.event_exited.dapui_config = dapui.close
  end,
}
