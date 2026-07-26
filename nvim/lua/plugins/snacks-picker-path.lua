-- Keep the first N leading path segments visible when the Snacks picker
-- truncates long paths. In a monorepo like `apps/wallet/...`, the default
-- Snacks behaviour only keeps the first segment, producing `apps/…/etc/etc`,
-- which hides the app name. This keeps `apps/wallet/…/etc` instead.
--
-- Change `keep` below to control how many leading segments are preserved.
return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    local keep = 2 -- number of leading path segments to always keep

    local Util = require("snacks.picker.util")
    if not Util._keep_head_patched then
      Util._keep_head_patched = true

      local orig = Util.truncpath
      Util.truncpath = function(path, len, o)
        o = o or {}
        -- Only customise the default (middle) truncation; leave the explicit
        -- left/right kinds (used by git branch, links, etc.) untouched.
        if o.kind == "left" or o.kind == "right" then
          return orig(path, len, o)
        end

        local cwd = vim.fs.normalize(o.cwd or vim.fn.getcwd(0))
        local home = vim.fs.normalize("~")
        path = vim.fs.normalize(path)

        -- Strip cwd / git root / home prefix, mirroring the original.
        if path:find(cwd .. "/", 1, true) == 1 and #path > #cwd then
          path = path:sub(#cwd + 2)
        else
          local root = Snacks.git.get_root(path)
          if root and root ~= "" and path:find(root, 1, true) == 1 then
            local tail = vim.fn.fnamemodify(root, ":t")
            path = "⋮" .. tail .. "/" .. path:sub(#root + 2)
          elseif path:find(home, 1, true) == 1 then
            path = "~" .. path:sub(#home + 1)
          end
        end
        path = path:gsub("/$", "")

        if vim.api.nvim_strwidth(path) <= len then
          return path
        end

        local parts = vim.split(path, "/")
        if #parts < 2 then
          return path
        end

        -- Take the first `keep` segments (clamped) as the fixed head.
        local head = {}
        for _ = 1, math.min(keep, #parts - 1) do
          table.insert(head, table.remove(parts, 1))
        end
        local first = table.concat(head, "/")
        local ret = table.remove(parts) -- filename (last segment)
        local width = vim.api.nvim_strwidth(ret) + vim.api.nvim_strwidth(first) + 3
        if width > len then
          return first .. "/…/" .. Util.truncate(ret, len - vim.api.nvim_strwidth(first) - 3, true)
        end
        if #parts == 0 then
          return first .. "/" .. ret
        end
        -- Fill trailing segments back in until we run out of room.
        while width < len and #parts > 0 do
          local part = table.remove(parts) .. "/"
          local w = vim.api.nvim_strwidth(part)
          if width + w > len then
            break
          end
          ret = part .. ret
          width = width + w
        end
        return first .. "/…/" .. ret
      end
    end

    return opts
  end,
}
