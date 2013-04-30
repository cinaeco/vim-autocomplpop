"=============================================================================
" Copyright (c) 2007-2009 Takeshi NISHIDA
"
" GetLatestVimScripts: 1879 1 :AutoInstall: AutoComplPop
"=============================================================================
" LOAD GUARD {{{1

if exists('g:loaded_acp') && g:loaded_acp
  finish
endif
let g:loaded_acp = 1

" }}}1
"=============================================================================
" FUNCTION: {{{1

"
function s:makeDefaultBehavior()
  let behavs = {
        \   '*'         : [],
        \   'ruby'      : [],
        \   'python'    : [],
        \   'perl'      : [],
        \   'xml'       : [],
        \   'html'      : [],
        \   'xhtml'     : [],
        \   'css'       : [],
        \   'javascript': [],
        \   'coffee'    : [],
        \   'ls'        : [],
        \ }
  "---------------------------------------------------------------------------
  if !empty(g:acp_behaviorUserDefinedFunction) &&
        \ !empty(g:acp_behaviorUserDefinedMeets)
    for key in keys(behavs)
      call add(behavs[key], {
            \   'command'      : "\<C-x>\<C-u>",
            \   'completefunc' : g:acp_behaviorUserDefinedFunction,
            \   'meets'        : g:acp_behaviorUserDefinedMeets,
            \   'repeat'       : 0,
            \ })
    endfor
  endif
  "---------------------------------------------------------------------------
  for key in keys(behavs)
    call add(behavs[key], {
          \   'command'      : "\<C-x>\<C-u>",
          \   'completefunc' : 'acp#completeSnipmate',
          \   'meets'        : 'acp#meetsForSnipmate',
          \   'onPopupClose' : 'acp#onPopupCloseSnipmate',
          \   'repeat'       : 0,
          \ })
  endfor
  "---------------------------------------------------------------------------
  for key in keys(behavs)
    call add(behavs[key], {
          \   'command' : g:acp_behaviorKeywordCommand,
          \   'meets'   : 'acp#meetsForKeyword',
          \   'repeat'  : 0,
          \ })
  endfor
  "---------------------------------------------------------------------------
  for key in keys(behavs)
    call add(behavs[key], {
          \   'command' : "\<C-x>\<C-f>",
          \   'meets'   : 'acp#meetsForFile',
          \   'repeat'  : 1,
          \ })
  endfor
  "---------------------------------------------------------------------------
  call add(behavs.ruby, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForRubyOmni',
        \   'repeat'  : 0,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.python, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForPythonOmni',
        \   'repeat'  : 0,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.perl, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForPerlOmni',
        \   'repeat'  : 0,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.xml, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForXmlOmni',
        \   'repeat'  : 1,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.html, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForHtmlOmni',
        \   'repeat'  : 1,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.xhtml, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForHtmlOmni',
        \   'repeat'  : 1,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.css, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForCssOmni',
        \   'repeat'  : 0,
        \ })
  "---------------------------------------------------------------------------
  call add(behavs.javascript, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForJavaScriptOmni',
        \   'repeat'  : 0,
  \})
  call add(behavs.coffee, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForJavaScriptOmni',
        \   'repeat'  : 0,
  \})
  call add(behavs.ls, {
        \   'command' : "\<C-x>\<C-o>",
        \   'meets'   : 'acp#meetsForJavaScriptOmni',
        \   'repeat'  : 0,
  \})
  return behavs
endfunction

" }}}1
"=============================================================================
" INITIALIZATION {{{1
hi AutoComplPopColorDefaultForward  ctermfg=Black ctermbg=Cyan guibg=LightCyan guifg=Black
hi AutoComplPopColorDefaultReverse  ctermfg=Black ctermbg=Magenta guibg=LightMagenta guifg=Black

"-----------------------------------------------------------------------------
function! s:defineVariableDefault(var, value)
  let g:{a:var} = get(g:, a:var, a:value)
endfunction
call s:defineVariableDefault('acp_enableAtStartup', 1)
call s:defineVariableDefault('acp_mappingDriven', 0)
call s:defineVariableDefault('acp_ignorecaseOption', 1)
call s:defineVariableDefault('acp_autoselectFirstCompletion', 1)
call s:defineVariableDefault('acp_completeOption', '.,w,b,k')
call s:defineVariableDefault('acp_completeoptPreview', 0)
call s:defineVariableDefault('acp_colorForward', 'AutoComplPopColorDefaultForward')
call s:defineVariableDefault('acp_colorReverse', 'AutoComplPopColorDefaultReverse')
call s:defineVariableDefault('acp_nextItemMapping', ['<TAB>', '\<lt>TAB>'])
call s:defineVariableDefault('acp_previousItemMapping', ['<S-TAB>', '\<lt>S-TAB>'])
call s:defineVariableDefault('acp_reverseMappingInReverseMenu', 1)
call s:defineVariableDefault('acp_behaviorUserDefinedFunction', '')
call s:defineVariableDefault('acp_behaviorUserDefinedMeets', '')
call s:defineVariableDefault('acp_behaviorSnipmateLength', -1)
call s:defineVariableDefault('acp_behaviorKeywordCommand', "\<C-n>")
call s:defineVariableDefault('acp_behaviorKeywordLength', 2)
call s:defineVariableDefault('acp_behaviorKeywordIgnores', [])
call s:defineVariableDefault('acp_behaviorFileLength', 0)
call s:defineVariableDefault('acp_behaviorRubyOmniMethodLength', 0)
call s:defineVariableDefault('acp_behaviorRubyOmniSymbolLength', 1)
call s:defineVariableDefault('acp_behaviorPythonOmniLength', 0)
call s:defineVariableDefault('acp_behaviorPerlOmniLength', -1)
call s:defineVariableDefault('acp_behaviorXmlOmniLength', 0)
call s:defineVariableDefault('acp_behaviorHtmlOmniLength', 0)
call s:defineVariableDefault('acp_behaviorCssOmniPropertyLength', 1)
call s:defineVariableDefault('acp_behaviorCssOmniValueLength', 0)
call s:defineVariableDefault('acp_behavior', {})
"-----------------------------------------------------------------------------
call extend(g:acp_behavior, s:makeDefaultBehavior(), 'keep')
"-----------------------------------------------------------------------------
command! -bar -narg=0 AcpEnable  call acp#enable()
command! -bar -narg=0 AcpDisable call acp#disable()
command! -bar -narg=0 AcpLock    call acp#lock()
command! -bar -narg=0 AcpUnlock  call acp#unlock()
"-----------------------------------------------------------------------------
" legacy commands
command! -bar -narg=0 AutoComplPopEnable  AcpEnable
command! -bar -narg=0 AutoComplPopDisable AcpDisable
command! -bar -narg=0 AutoComplPopLock    AcpLock
command! -bar -narg=0 AutoComplPopUnlock  AcpUnlock
"-----------------------------------------------------------------------------
if g:acp_enableAtStartup
  AcpEnable
endif
"-----------------------------------------------------------------------------

" }}}1
"=============================================================================
" vim: set fdm=marker:
