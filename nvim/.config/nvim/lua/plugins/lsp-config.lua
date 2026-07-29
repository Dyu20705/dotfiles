return {
    {
        "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonLog" },
    config = function()
        require("mason").setup()
    end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        auto_install = false,
        ensure_installed = {
            "clangd",   -- C/C++
            "lua_ls",   -- Neovim Lua
            "zls",      -- Zig
            "pyright",  -- Python
            "rust_analyzer", -- Rust
            "dockerls", -- Dockerfile
        },
    },
    },
    {
        "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp" },
    config = function()
        local capabilities = require("blink.cmp").get_lsp_capabilities()

        local function setup(server_name, server_config)
            server_config = server_config or {}
            server_config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})
            vim.lsp.config(server_name, server_config)
        end

        -- C / C++
        setup("clangd")

        -- Lua
        setup("lua_ls", {
            settings = {
                Lua = {
                    runtime = {
                        version = "LuaJIT",
                    },
                    diagnostics = {
                        globals = { "vim" },
                    },
                    workspace = {
                        checkThirdParty = false,
                        library = vim.api.nvim_get_runtime_file("", true),
                    },
                    telemetry = {
                        enable = false,
                    },
                    completion = {
                        callSnippet = "Replace",
                    },
                },
            },
        })

        -- Zig
        setup("zls")

        -- Python
        setup("pyright")

        -- Rust
        setup("rust_analyzer")

        -- Docker
        setup("dockerls")

        -- enable
        vim.lsp.enable({
            "clangd",
            "lua_ls",
            "zls",
            "pyright",
            "rust_analyzer",
            "dockerls",
        })

        -- keymaps
        vim.keymap.set("n", "K", vim.lsp.buf.hover)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
        vim.keymap.set("n", "gr", vim.lsp.buf.references)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action)
    end,
    }
}
