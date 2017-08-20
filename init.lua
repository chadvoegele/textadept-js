local tajs = {}

if type(snippets) == 'table' then
  snippets.javascript = {
    logjs = 'console.log(JSON.stringify(%1(obj)));'
  }
end

tajs.options = {
  checkers = {{
    command = 'jshint',
    -- chart.js: line 44, col 2, Missing semicolon.
    parser = function (line) return line:match(".*:%s+line%s+(%d+),%s+col%s+%d+,%s(.*)$") end
  }, {
    command = 'jscs -r inline',
    -- chart.js: line 114, col 18, validateQuoteMarks: Invalid quote mark found
    parser = function (line) return line:match(".*:%s+line%s+(%d+),%s+col%s+%d+,%s(.*)$") end
  }}
}

-- Following https://github.com/rgieseke/textadept-python/blob/master/init.lua
-- Annotates and navigates to first error found.
tajs.check = function ()
  if buffer:get_lexer() ~= 'javascript' then
    return
  end

  buffer:annotation_clear_all()
  for _, s in pairs(tajs.options.checkers) do
    local command = s.command..' '..buffer.filename..' 2>&1'
    local p = io.popen(command)
    local out = p:read('*line')
    local _, _, rc = p:close()
    if rc == 127 then
      ui.print(out)
      return
    end
    if out then
      local line, err_msg = s.parser(out)
      if line then
        buffer.annotation_visible = 2
        buffer.annotation_text[line - 1] = err_msg
        buffer.annotation_style[line - 1] = 8
        buffer:goto_line(line - 1)
        return
      end
    end
  end
end

tajs.init = function ()
  events.connect(events.FILE_AFTER_SAVE, tajs.check)
  return tajs
end

return tajs
