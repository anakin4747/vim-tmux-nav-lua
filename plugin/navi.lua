
local debug = true

do -- Initial checks
    if loaded_navigator ~= nil and debug == false then
        vim.notify('vim-tmux-navi-lua already loaded', vim.log.levels.WARN)
        return
    end

    if vim.o.compatible then
        vim.notify(
            'vim-tmux-navi-lua compatible mode not supported',
            vim.log.levels.ERROR
        )
        return
    end

    -- TODO: Figure out lowest supported version number
end

loaded_navigator = 1

local function num_of_tmux_panes ()
    return tonumber(vim.fn.system("tmux list-panes -F '#{pane_id}' | wc -l") or 0)
end

-------------
--  Navigates windows in Vim or Tmux.
--  @param args.key The key associated with the direction to navigate to
--  @param args.vim_mode Boolean to determine whether the navigation is vim or tmux
function Navigate (args)
    assert(args.key ~= nil, "no key provided")
    assert(string.find("hjklp", args.key), "key not valid")

    -- vim navigation
    if args.vim_mode or num_of_tmux_panes() == 1 then
        local status, err = pcall(
            vim.api.nvim_command, "wincmd " .. args.key
        )
        if not status then
            vim.notify(
                'vim_navigate: failed to call wincmd. ' .. tostring(err),
                vim.log.levels.error
            )
        end
        return
    end

    -- try vim navigation first and test if movement happened
    local winnr_prev = vim.fn.winnr()
    Navigate { key = args.key, vim_mode = true }
    if winnr_prev ~= vim.fn.winnr() then
        return -- Movement in vim occured
    end

    -- tmux navigation
    vim.notify("TMUX TMUX")
end

-- Set vim_mode based on $TMUX
local tmux_string = os.getenv("TMUX")
local vim_mode = false
if tmux_string == '' or tmux_string == nil then
    vim_mode = true
end

local key_to_direction = {
    h = 'left',
    j = 'bottom', -- tmux specific naming
    k = 'top', -- tmux specific naming
    l = 'right',
    p = 'prev'
}

-- Create commands for all directions
for key, direction in pairs(key_to_direction) do
    vim.cmd(
        "command! Navigate" .. direction ..
        " lua Navigate { key = '" .. key .. "'," ..
        " vim_mode = " .. tostring(vim_mode) .. " }"
    )
    vim.api.nvim_set_keymap(
        "n", "<M-" .. key .. ">", ":<C-U>Navigate" .. direction .. "<cr>",
        { noremap = true, silent = true }
    )
end
