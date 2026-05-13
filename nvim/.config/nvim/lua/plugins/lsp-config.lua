return {
    {
    "williamboman/mason.nvim",
    config = function() 
        require("mason").setup()
    end,
    },
    {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    opts = {
        auto_install = true,
        ensure_installed = {
            "clangd",   -- C/C++
            "zls",      -- Zig
            "pyright",  -- Python
            "rust_analyzer", -- Rust
            "dockerls", -- Dockerfile
        },
    },
    },
    {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        -- C / C++
        vim.lsp.config["clangd"] = {
            capabilities = capabilities,
        }

        -- Zig
        vim.lsp.config["zls"] = {
            capabilities = capabilities,
        }

        -- Python
        vim.lsp.config["pyright"] = {
            capabilities = capabilities,
        }

        -- Rust
        vim.lsp.config["rust_analyzer"] = {
            capabilities = capabilities,
        }

        -- Docker
        vim.lsp.config["dockerls"] = {
            capabilities = capabilities,
        }

        -- enable
        vim.lsp.enable({
            "clangd",
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
