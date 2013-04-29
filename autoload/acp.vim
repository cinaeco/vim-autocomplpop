"=============================================================================
" Copyright (c) 2007-2009 Takeshi NISHIDA
"
"=============================================================================
" LOAD GUARD {{{1

if exists('s:loaded_acp') && s:loaded_acp
  finish
endif
let s:loaded_acp = 1

" }}}1
"=============================================================================
" GLOBAL FUNCTIONS: {{{1

"
function acp#enable()
  call acp#disable()

  augroup AcpGlobalAutoCommand
    autocmd!
    autocmd InsertEnter * unlet! s:posLast s:lastUncompletable
    autocmd InsertLeave * call s:finishPopup(1)
  augroup END

  if g:acp_mappingDriven
    call s:mapForMappingDriven()
  else
    autocmd AcpGlobalAutoCommand CursorMovedI * call s:feedPopup()
  endif

  nnoremap <silent> i i<C-r>=<SID>feedPopup()<CR>
  nnoremap <silent> a a<C-r>=<SID>feedPopup()<CR>
  nnoremap <silent> R R<C-r>=<SID>feedPopup()<CR>
endfunction

"
function acp#disable()
  call s:unmapForMappingDriven()
  augroup AcpGlobalAutoCommand
    autocmd!
  augroup END
  nnoremap i <Nop> | nunmap i
  nnoremap a <Nop> | nunmap a
  nnoremap R <Nop> | nunmap R
endfunction

"
function acp#lock()
  let s:lockCount += 1
endfunction

"
function acp#unlock()
  let s:lockCount -= 1
  if s:lockCount < 0
    let s:lockCount = 0
    throw "AutoComplPop: not locked"
  endif
endfunction

"
function acp#meetsForSnipmate(context)
  if g:acp_behaviorSnipmateLength < 0
    return 0
  endif
  let matches = matchlist(a:context, '\(^\|\s\|\<\)\(\u\{' .
        \                            g:acp_behaviorSnipmateLength . ',}\)$')
  return !empty(matches) && !empty(s:getMatchingSnipItems(matches[2]))
endfunction

"
function acp#meetsForKeyword(context)
  if g:acp_behaviorKeywordLength < 0
    return 0
  endif
  let matches = matchlist(a:context, '\(\k\{' . g:acp_behaviorKeywordLength . ',}\)$')
  if empty(matches)
    return 0
  endif
  for ignore in g:acp_behaviorKeywordIgnores
    if stridx(ignore, matches[1]) == 0
      return 0
    endif
  endfor
  return 1
endfunction

"
function acp#meetsForFile(context)
  if g:acp_behaviorFileLength < 0
    return 0
  endif
  if has('win32') || has('win64')
    let separator = '[/\\]'
  else
    let separator = '\/'
  endif
  if a:context !~ '\f' . separator . '\f\{' . g:acp_behaviorFileLength . ',}$'
    return 0
  endif
  return a:context !~ '[*/\\][/\\]\f*$\|[^[:print:]]\f*$'
endfunction

"
function acp#meetsForRubyOmni(context)
  if !has('ruby')
    return 0
  endif
  if g:acp_behaviorRubyOmniMethodLength >= 0 &&
        \ a:context =~ '[^. \t]\(\.\|::\)\k\{' .
        \              g:acp_behaviorRubyOmniMethodLength . ',}$'
    return 1
  endif
  if g:acp_behaviorRubyOmniSymbolLength >= 0 &&
        \ a:context =~ '\(^\|[^:]\):\k\{' .
        \              g:acp_behaviorRubyOmniSymbolLength . ',}$'
    return 1
  endif
  return 0
endfunction

"
function acp#meetsForPythonOmni(context)
  if !has('python') || g:acp_behaviorPythonOmniLength < 0
    return 0
  endif
  if g:acp_behaviorPythonOmniLength == 0
    return 1
  endif
  let matches = matchlist(a:context, '\(\(\k\|\.\|(\)\{' . g:acp_behaviorPythonOmniLength . ',}\)$')
  if empty(matches)
    return 0
  endif
  return 1
endfunction

"
function acp#meetsForPerlOmni(context)
  return g:acp_behaviorPerlOmniLength >= 0 &&
        \ a:context =~ '\w->\k\{' . g:acp_behaviorPerlOmniLength . ',}$'
endfunction

"
function acp#meetsForXmlOmni(context)
  return g:acp_behaviorXmlOmniLength >= 0 &&
        \ a:context =~ '\(<\|<\/\|<[^>]\+ \|<[^>]\+=\"\)\k\{' .
        \              g:acp_behaviorXmlOmniLength . ',}$'
endfunction

"
function acp#meetsForHtmlOmni(context)
    if g:acp_behaviorHtmlOmniLength >= 0
        if a:context =~ '\(<\|<\/\|<[^>]\+ \|<[^>]\+=\"\)\k\{' .g:acp_behaviorHtmlOmniLength . ',}$'
            return 1
        elseif a:context =~ '\(\<\k\{1,}\(=\"\)\{0,1}\|\" \)$'
            let cur = line('.')-1
            while cur > 0
                let lstr = getline(cur)
                if lstr =~ '>[^>]*$'
                    return 0
                elseif lstr =~ '<[^<]*$'
                    return 1
                endif
                let cur = cur-1
            endwhile
            return 0
        endif
    else
        return 0
    endif
endfunction

"
function acp#meetsForCssOmni(context)
  if g:acp_behaviorCssOmniPropertyLength >= 0 &&
        \ a:context =~ '\(^\s\|[;{]\)\s*\k\{' .
        \              g:acp_behaviorCssOmniPropertyLength . ',}$'
    return 1
  endif
  if g:acp_behaviorCssOmniValueLength >= 0 &&
        \ a:context =~ '[:@!]\s*\k\{' .
        \              g:acp_behaviorCssOmniValueLength . ',}$'
    return 1
  endif
  return 0
endfunction

"
function acp#meetsForJavaScriptOmni(context)
    let matches = matchlist(a:context, '\(\k\{1}\)$')
    if empty(matches)
        return 0
    endif
    return 1
endfunction

"
function acp#completeSnipmate(findstart, base)
  if a:findstart
    let s:posSnipmateCompletion = len(matchstr(s:getCurrentText(), '.*\U'))
    return s:posSnipmateCompletion
  endif
  let lenBase = len(a:base)
  let items = snipMate#GetSnippetsForWordBelowCursor(a:base, '\c', 0)
  call filter(items, 'strpart(v:val[0], 0, len(a:base)) ==? a:base')
  return map(sort(items), 's:makeSnipmateItem(v:val[0], values(v:val[1])[0])')
endfunction

"
function acp#onPopupCloseSnipmate()
  let word = s:getCurrentText()[s:posSnipmateCompletion :]
  if len(snipMate#GetSnippetsForWordBelowCursor(word, '\c', 0))
    call feedkeys("\<C-r>=snipMate#TriggerSnippet()\<CR>", "n")
    return 0
  endif
  return 1
endfunction

"
function acp#onPopupPost()
  " to clear <C-r>= expression on command-line
  echo ''
  if pumvisible() && exists('s:behavsCurrent[s:iBehavs]')
    inoremap <silent> <expr> <C-h> acp#onBs()
    inoremap <silent> <expr> <BS>  acp#onBs()
    let l:autoselect_up = ""
    let l:autoselect_down = ""
    if g:acp_autoselectFirstCompletion
        let l:autoselect_up = "\<Up>"
        let l:autoselect_down = "\<Down>"
    endif
    " a command to restore to original text and select the first match
    return (s:behavsCurrent[s:iBehavs].command =~# "\<C-p>"
          \             ? "\<C-n>" . l:autoselect_up
          \             : "\<C-p>" . l:autoselect_down)
  endif
  let s:iBehavs += 1
  if len(s:behavsCurrent) > s:iBehavs 
    call s:setCompletefunc()
    call acp#pum_color_and_map_adaptions(0)
    return printf("\<C-e>%s\<C-r>=acp#onPopupPost()\<CR>",
          \       s:behavsCurrent[s:iBehavs].command)
  else
    let s:lastUncompletable = {
          \   'word': s:getCurrentWord(),
          \   'commands': map(copy(s:behavsCurrent), 'v:val.command')[1:],
          \ }
    call s:finishPopup(0)
    return "\<C-e>"
  endif
endfunction

function acp#pum_color_and_map_adaptions(force_direction)
    " force_direction
    " 0 : no forcing, command conditional acp selection
    " 1 : force forward
    " 2 : force reverse
    let l:direction = a:force_direction
    if a:force_direction == 0
        if s:behavsCurrent[s:iBehavs].command =~? "\<C-p>"
            let l:direction = 2
        else
            let l:direction = 1
        endif
    endif
    if l:direction == 1
        execute 'inoremap ' . g:acp_nextItemMapping[0]
                    \ . ' <C-R>=pumvisible() ? "\<lt>C-N>" : "'
                    \ . g:acp_nextItemMapping[1] . '"<CR>'
        execute 'inoremap ' . g:acp_previousItemMapping[0]
                    \ . ' <C-R>=pumvisible() ? "\<lt>C-P>" : "'
                    \ . g:acp_previousItemMapping[1] . '"<CR>'
        execute "hi! link Pmenu " . g:acp_colorForward
    elseif l:direction == 2
        execute 'inoremap ' . g:acp_nextItemMapping[0]
                    \ . ' <C-R>=pumvisible() ? "\<lt>C-P>" : "'
                    \ . g:acp_nextItemMapping[1] . '"<CR>'
        execute 'inoremap ' . g:acp_previousItemMapping[0]
                    \ . ' <C-R>=pumvisible() ? "\<lt>C-N>" : "'
                    \ . g:acp_previousItemMapping[1] . '"<CR>'
        execute "hi! link Pmenu " . g:acp_colorReverse
    else
        throw "acp: color/map adaption: Invalid direction argument"
    endif
    return ''
endfunction

"
function acp#onBs()
  " using "matchstr" and not "strpart" in order to handle multi-byte
  " characters
  if call(s:behavsCurrent[s:iBehavs].meets,
        \ [matchstr(s:getCurrentText(), '.*\ze.')])
    return "\<BS>"
  endif
  return "\<C-e>\<BS>"
endfunction

" }}}1
"=============================================================================
" LOCAL FUNCTIONS: {{{1

"
function s:mapForMappingDriven()
  call s:unmapForMappingDriven()
  let s:keysMappingDriven = [
        \ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
        \ 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
        \ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
        \ 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
        \ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        \ '-', '_', '~', '^', '.', ',', ':', '!', '#', '=', '%', '$', '@', '<', '>', '/', '\',
        \ '<Space>', '<C-h>', '<BS>', ]
  for key in s:keysMappingDriven
    execute printf('inoremap <silent> %s %s<C-r>=<SID>feedPopup()<CR>',
          \        key, key)
  endfor
endfunction

"
function s:unmapForMappingDriven()
  if !exists('s:keysMappingDriven')
    return
  endif
  for key in s:keysMappingDriven
    execute 'iunmap ' . key
  endfor
  let s:keysMappingDriven = []
endfunction

"
function s:getCurrentWord()
  return matchstr(s:getCurrentText(), '\k*$')
endfunction

"
function s:getCurrentText()
  return strpart(getline('.'), 0, col('.') - 1)
endfunction

"
function s:getPostText()
  return strpart(getline('.'), col('.') - 1)
endfunction

"
function s:isModifiedSinceLastCall()
  if exists('s:posLast')
    let posPrev = s:posLast
    let nLinesPrev = s:nLinesLast
    let textPrev = s:textLast
  endif
  let s:posLast = getpos('.')
  let s:nLinesLast = line('$')
  let s:textLast = getline('.')
  if !exists('posPrev')
    return 1
  elseif posPrev[1] != s:posLast[1] || nLinesPrev != s:nLinesLast
    return (posPrev[1] - s:posLast[1] == nLinesPrev - s:nLinesLast)
  elseif textPrev ==# s:textLast
    return 0
  elseif posPrev[2] > s:posLast[2]
    return 1
  elseif has('gui_running') && has('multi_byte')
    " NOTE: auto-popup causes a strange behavior when IME/XIM is working
    return posPrev[2] + 1 == s:posLast[2]
  endif
  return posPrev[2] != s:posLast[2]
endfunction

"
function s:makeCurrentBehaviorSet()
  let modified = s:isModifiedSinceLastCall()
  if exists('s:behavsCurrent[s:iBehavs].repeat') && s:behavsCurrent[s:iBehavs].repeat
    let behavs = [ s:behavsCurrent[s:iBehavs] ]
  elseif exists('s:behavsCurrent[s:iBehavs]')
    return []
  elseif modified
    let behavs = copy(exists('g:acp_behavior[&filetype]')
          \           ? g:acp_behavior[&filetype]
          \           : g:acp_behavior['*'])
  else
    return []
  endif
  let text = s:getCurrentText()
  call filter(behavs, 'call(v:val.meets, [text])')
  let s:iBehavs = 0
  if exists('s:lastUncompletable') &&
        \ stridx(s:getCurrentWord(), s:lastUncompletable.word) == 0 &&
        \ map(copy(behavs), 'v:val.command') ==# s:lastUncompletable.commands
    let behavs = []
  else
    unlet! s:lastUncompletable
  endif
  return behavs
endfunction

"
function s:isInputAsMultibyte()
  let line = getline('.')
  let col = col('.')
  return char2nr(line[col-2]) > 0x80
        \  || line[col-3 : col-2] =~? '[kstnhmyrwgzdbpcfj][yh]'
endfunction

"
function s:feedPopup()
  " NOTE: CursorMovedI is not triggered while the popup menu is visible. And
  "       it will be triggered when popup menu is disappeared.
  if has('multi_byte') && s:isInputAsMultibyte()
    call s:finishPopup(1)
    return ''
  endif
  if s:lockCount > 0 || pumvisible() || &paste
    return ''
  endif
  if exists('s:behavsCurrent[s:iBehavs].onPopupClose')
    if !call(s:behavsCurrent[s:iBehavs].onPopupClose, [])
      call s:finishPopup(1)
      return ''
    endif
  endif
  let s:behavsCurrent = s:makeCurrentBehaviorSet()
  if empty(s:behavsCurrent)
    call s:finishPopup(1)
    return ''
  endif
  " In case of dividing words by symbols (e.g. "for(int", "ab==cd") while a
  " popup menu is visible, another popup is not available unless input <C-e>
  " or try popup once. So first completion is duplicated.
  call insert(s:behavsCurrent, s:behavsCurrent[s:iBehavs])
  call acp#tempvariables#set(s:TEMP_VARIABLES_GROUP0,
        \ '&spell', 0)
  call acp#tempvariables#set(s:TEMP_VARIABLES_GROUP0,
        \ '&completeopt', 'menuone' . (g:acp_completeoptPreview ? ',preview' : ''))
  call acp#tempvariables#set(s:TEMP_VARIABLES_GROUP0,
        \ '&complete', g:acp_completeOption)
  call acp#tempvariables#set(s:TEMP_VARIABLES_GROUP0,
        \ '&ignorecase', g:acp_ignorecaseOption)
  " NOTE: With CursorMovedI driven, Set 'lazyredraw' to avoid flickering.
  "       With Mapping driven, set 'nolazyredraw' to make a popup menu visible.
  call acp#tempvariables#set(s:TEMP_VARIABLES_GROUP0,
        \ '&lazyredraw', !g:acp_mappingDriven)
  " NOTE: 'textwidth' must be restored after <C-e>.
  call acp#tempvariables#set(s:TEMP_VARIABLES_GROUP1,
        \ '&textwidth', 0)

  call acp#pum_color_and_map_adaptions(0)

  call s:setCompletefunc()
  call feedkeys(s:behavsCurrent[s:iBehavs].command . "\<C-r>=acp#onPopupPost()\<CR>", 'n')
  return '' " this function is called by <C-r>=
endfunction

"
function s:finishPopup(fGroup1)
  inoremap <C-h> <Nop> | iunmap <C-h>
  inoremap <BS>  <Nop> | iunmap <BS>
  let s:behavsCurrent = []
  call acp#tempvariables#end(s:TEMP_VARIABLES_GROUP0)
  if a:fGroup1
    call acp#tempvariables#end(s:TEMP_VARIABLES_GROUP1)
  endif
endfunction

"
function s:setCompletefunc()
  if exists('s:behavsCurrent[s:iBehavs].completefunc')
    call acp#tempvariables#set(s:TEMP_VARIABLES_GROUP0,
          \ '&completefunc', s:behavsCurrent[s:iBehavs].completefunc)
  endif
endfunction

"
function s:makeSnipmateItem(key, snip)
  if type(a:snip) == type([])
    let descriptions = map(copy(a:snip), 'v:val[0]')
    let snipFormatted = '[MULTI] ' . join(descriptions, ', ')
  elseif type(a:snip) == type({})
    let descriptions = values(a:snip)[0]
    let snipFormatted = substitute(descriptions, '\(\n\|\s\)\+', ' ', 'g')
  else
    let snipFormatted = substitute(a:snip, '\(\n\|\s\)\+', ' ', 'g')
  endif
  return  {
        \   'word': a:key,
        \   'menu': strpart(snipFormatted, 0, 80),
        \ }
endfunction

"
function s:getMatchingSnipItems(base)
  let key = a:base . "\n"
  if !exists('s:snipItems[key]')
    let s:snipItems[key] = snipMate#GetSnippetsForWordBelowCursor(a:base, '\c', 0)
    call filter(s:snipItems[key], 'strpart(v:val[0], 0, len(a:base)) ==? a:base')
    call map(s:snipItems[key], 's:makeSnipmateItem(v:val[0], v:val[1])')
  endif
  return s:snipItems[key]
endfunction

" }}}1
"=============================================================================
" INITIALIZATION {{{1

let s:TEMP_VARIABLES_GROUP0 = "AutoComplPop0"
let s:TEMP_VARIABLES_GROUP1 = "AutoComplPop1"
let s:lockCount = 0
let s:behavsCurrent = []
let s:iBehavs = 0
let s:snipItems = {}

" }}}1
"=============================================================================
" vim: set fdm=marker:
