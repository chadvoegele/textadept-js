local tajs = {}

if type(snippets) == 'table' then
  snippets.javascript = {
    logjs = 'console.log(JSON.stringify(%1(obj)));'
  }
end

tajs.find_config = function (directory, config)
  local up_directory = directory:match('^(.*)[/\\]')
  if up_directory == nil then return nil end
  local path_sep = package.config:sub(1,1)
  local config_guess = up_directory..path_sep..config
  if lfs.attributes(config_guess) then return config_guess end
  return tajs.find_config(up_directory, config)
end

tajs.options = {
  checkers = {{
    command = 'jshint',
    config = '.jshintrc',
    -- chart.js: line 44, col 2, Missing semicolon.
    parser = function (line) return line:match(".*:%s+line%s+(%d+),%s+col%s+%d+,%s(.*)$") end
  }, {
    command = 'jscs -r inline',
    config = '.jscsrc',
    -- chart.js: line 114, col 18, validateQuoteMarks: Invalid quote mark found
    parser = function (line) return line:match(".*:%s+line%s+(%d+),%s+col%s+%d+,%s(.*)$") end
  }, {
    command = 'eslint -f compact',
    config = '.eslintrc',
    -- chart.js: line 114, col 18, validateQuoteMarks: Invalid quote mark found
    parser = function (line) return line:match(".*:%s+line%s+(%d+),%s+col%s+%d+,%s(.*)$") end
  }}
}

-- Following https://github.com/rgieseke/textadept-python/blob/master/init.lua
-- Annotates all errors.
tajs.check = function ()
  if buffer:get_lexer() ~= 'javascript' then
    return
  end

  buffer:annotation_clear_all()
  for _, s in pairs(tajs.options.checkers) do
    local config = tajs.find_config(buffer.filename, s.config)
    if config ~= nil then
      local command = s.command..' '..buffer.filename..' 2>&1'
      local p = io.popen(command)
      local out
      while true do
        out = p:read('*line')
        if not out then break end
        local line, err_msg = s.parser(out)
        if not line then break end
        buffer.annotation_visible = 2
        buffer.annotation_text[line - 1] = err_msg
        buffer.annotation_style[line - 1] = 8
      end
      local _, _, rc = p:close()
      if rc == 127 then
        ui.print(out)
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
