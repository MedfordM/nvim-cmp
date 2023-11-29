local window = require('cmp.utils.window')
local config = require('cmp.config')

---@class cmp.DocsView
---@field public window cmp.Window
local docs_view = {}

---Create new floating window module
docs_view.new = function()
  local self = setmetatable({}, { __index = docs_view })
  self.entry = nil
  self.window = window.new()
  self.window:option('conceallevel', 2)
  self.window:option('concealcursor', 'n')
  self.window:option('foldenable', false)
  self.window:option('linebreak', true)
  self.window:option('scrolloff', 0)
  self.window:option('showbreak', 'NONE')
  self.window:option('wrap', true)
  self.window:buffer_option('filetype', 'cmp_docs')
  self.window:buffer_option('buftype', 'nofile')
  return self
end

---Open documentation window
---@param e cmp.Entry
---@param view cmp.WindowStyle
docs_view.open = function(self, e, view)
  local documentation = config.get().window.documentation
  if not documentation then
    return
  end

  if not e or not view then
    return self:close()
  end

  local border_info = window.get_border_info({ style = documentation })
  local right_space = vim.o.columns - (view.col + view.width) - 1
  local left_space = view.col - 1
  local max_width = math.min(documentation.max_width, math.max(left_space, right_space))
  local max_height = documentation.max_height
  local documents = {}

  -- Update buffer content if needed.
  if not self.entry or e.id ~= self.entry.id then
    documents = e:get_documentation()
    if #documents == 0 then
      return self:close()
    end
    self.entry = e
  end

  local initialDocStyle = {
    title = 'Docs',
    border = 'rounded',
    wrap = false,
    winhighlight = 'Normal:Normal,FloatBorder:Normal,CursorLine:Visual,Search:None',
    zindex = 1001,
    scrolloff = 0,
    col_offset = 0,
    side_padding = 1,
    scrollbar = true,
    width = max_width,
    height = max_height,
    relative = 'cursor',
    offset_x = view.col
  }
  local floatWinId = nil
  local _ = nil
  _, floatWinId = vim.lsp.util.open_floating_preview(documents, 'markdown', initialDocStyle)
  -- Set buffer as not modified, so it can be removed without errors
  vim.api.nvim_buf_set_option(self.window:get_buffer(), 'modified', false)

  -- Calculate window size.
  -- local width, height = vim.lsp.util._make_floating_popup_size(vim.api.nvim_buf_get_lines(self.window:get_buffer(), 0, -1, false), {
  --   max_width = max_width - border_info.horiz,
  --   max_height = documentation.max_height - border_info.vert,
  -- })
  -- if width <= 0 or height <= 0 then
  --   return self:close()
  -- end
  --
  -- -- Calculate window position.
  -- local right_col = view.col + view.width
  -- local left_col = view.col - width - border_info.horiz
  -- local col, left
  -- if right_space >= width and left_space >= width then
  --   if right_space < left_space then
  --     col = left_col
  --     left = true
  --   else
  --     col = right_col
  --   end
  -- elseif right_space >= width then
  --   col = right_col
  -- elseif left_space >= width then
  --   col = left_col
  --   left = true
  -- else
  --   return self:close()
  -- end
  --
  -- -- Render window.
  -- self.window:option('winblend', vim.o.pumblend)
  -- self.window:option('winhighlight', documentation.winhighlight)
  -- local adjustedDocStyle = {
  -- }
  --
  -- vim.api.nvim_win_set_config(floatWinId, adjustedDocStyle)
  -- self.window.update(self)
  --
  -- -- Correct left-col for scrollbar existence.
  -- if left then
  --   adjustedDocStyle.col = col - self.window:info().scrollbar_offset
  --   self.window:open(adjustedDocStyle)
  -- end
end

---Close floating window
docs_view.close = function(self)
  self.window:close()
  self.entry = nil
end

docs_view.scroll = function(self, delta)
  if self:visible() then
    local info = vim.fn.getwininfo(self.window.win)[1] or {}
    local top = info.topline or 1
    top = top + delta
    top = math.max(top, 1)
    top = math.min(top, self.window:get_content_height() - info.height + 1)

    vim.defer_fn(function()
      vim.api.nvim_buf_call(self.window:get_buffer(), function()
        vim.api.nvim_command('normal! ' .. top .. 'zt')
        self.window:update()
      end)
    end, 0)
  end
end

docs_view.visible = function(self)
  return self.window:visible()
end

return docs_view
