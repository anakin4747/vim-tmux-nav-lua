local debug = false

do -- Initial checks
    if Loaded and not debug then
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
end

Loaded = true

local key_to_dir = {
    h = 'left',
    j = 'bottom', -- tmux specific naming
    k = 'top', -- tmux specific naming
    l = 'right',
    p = 'prev'
}

--- Tmux helper functions.
-- Functions for interacting with tmux
-- @section tmux_helpers

--- Vim key to tmux direction
-- @param char The vim key to be translated
-- @return tmux direction character
local function tr (char)
    return string.gsub(
        char, "[phjkl]", { p = "l", h = "L", j = "D", k = "U", l = "R" }
    )
end

--- Get the tmux socket from $TMUX
-- @return first field of $TMUX delimited on commas
local function tmux_socket ()
    return os.getenv("TMUX"):match("([^,]+)")
end

--- Execute a tmux command
-- @param args Arguments to pass to tmux command
local function tmux_cmd (args)
    vim.fn.system("tmux -S " .. tmux_socket() .. ' ' .. args)
end

--- Navigates windows in Vim or Tmux.
-- @param args.key The key associated with the direction to navigate to
-- @param args.vim_mode Boolean to determine whether the navigation is vim or tmux
function Navigate (args)
    assert(args.key ~= nil, "no key provided")
    assert(key_to_dir[args.key] ~= nil, "key not valid")

    -- vim navigation
    if args.vim_mode then
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
    tmux_cmd(
        'if -F "#{pane_at_' .. key_to_dir[args.key] .. '}" "" "' ..
        'select-pane -t ' .. os.getenv("TMUX_PANE") .. ' -' ..
        tr(args.key) .. '"'
    )
end

-- Assume vim_mode based on $TMUX
local tmux_string = os.getenv("TMUX")
local vim_mode = false
if tmux_string == '' or tmux_string == nil then
    vim_mode = true -- not in tmux session
end

-- Create keybindings for all directions
for key, _ in pairs(key_to_dir) do
    local command = ":<C-U>lua Navigate { key = '" .. key .. "'," ..
        " vim_mode = " .. tostring(vim_mode) .. " }<cr>"
    vim.api.nvim_set_keymap(
        "n", "<M-" .. key .. ">", command,
        { noremap = true, silent = true }
    )
end
