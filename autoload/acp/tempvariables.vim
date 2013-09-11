"=============================================================================
" Copyright (C) 2010 Takeshi NISHIDA
"
"=============================================================================
" LOAD GUARD {{{1

if exists('s:loaded_acp_tempvariables') && s:loaded_acp_tempvariables
  finish
endif
let s:loaded_acp_tempvariables = 1

" }}}1
"=============================================================================
" TEMPORARY VARIABLES {{{1

"
let s:origMap = {}

" set temporary variables
function acp#tempvariables#set(group, name, value)
  if !exists('s:origMap[a:group]')
    let s:origMap[a:group] = {}
  endif
  if !exists('s:origMap[a:group][a:name]')
    let s:origMap[a:group][a:name] = eval(a:name)
  endif
  execute 'let ' . a:name . ' = a:value'
endfunction

" set temporary variables
function acp#tempvariables#setList(group, variables)
  for [name, value] in a:variables
    call acp#tempvariables#set(a:group, name, value)
    unlet value " to avoid E706
  endfor
endfunction

" get temporary variables
function acp#tempvariables#getList(group)
  if !exists('s:origMap[a:group]')
    return []
  endif
  return map(keys(s:origMap[a:group]), '[v:val, eval(v:val)]')
endfunction

" restore original variables and clean up.
function acp#tempvariables#end(group)
  if !exists('s:origMap[a:group]')
    return
  endif
  for [name, value] in items(s:origMap[a:group])
    execute 'let ' . name . ' = value'
    unlet value " to avoid E706
  endfor
  unlet s:origMap[a:group]
endfunction

" }}}1
"=============================================================================
" vim: set fdm=marker:

