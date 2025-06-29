require('vis')

function endsWith(str, suffix)
  return str:sub(-#suffix) == suffix
end


vis.events.subscribe(vis.events.WIN_OPEN, function(win)
  vis:command('set autoindent on')
  vis:command('set colorcolumn 80')
  vis:command('set number')
  vis:command('set show-spaces on')
  vis:command('set show-tabs on')

  if endsWith(win.file.name, ".nix") then
    vis:command('set expandtab on')
    vis:command('set tabwidth 2')
  else
    vis:command('set expandtab off')
    vis:command('set tabwidth 8')
  end
end)
