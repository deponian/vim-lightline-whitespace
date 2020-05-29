" MIT License. Copyright (c) 2013-2019 Bailey Ling et al.
" vim: et ts=2 sts=2 sw=2
" Modified By: Rufus Deponian <deponian@pm.me>

" http://got-ravings.blogspot.com/2008/10/vim-pr0n-statusline-whitespace-flags.html

let s:max_lines = get(g:, 'lightline#whitespace#max_lines', 20000)
let s:space = get(g:, 'lightline#whitespace#space', ' ')
let s:trailing_fmt = get(g:, 'lightline#whitespace#trailing_format', '[%s] trail')
let s:mixed_fmt = get(g:, 'lightline#whitespace#mixed_format', '[%s] mixed')
let s:inconsistent_fmt = get(g:, 'lightline#whitespace#inconsistent_format', '[%s] inconsistent')
let s:skip_check_ft = get(g:, 'lightline#whitespace#skip_check_ft', {})
let s:c_like_langs = get(g:, 'lightline#whitespace#c_like_langs', [])
let s:indentation_algorithm = get(g:, 'lightline#whitespace#indentation_algorithm', 0)

" whitespaces in the end of line
function! s:check_trailing_whitespaces()
  return search('\s$', 'nw')
endfunction

" mixed indent within a line
function! s:check_mixed_indentation()
  if s:indentation_algorithm == 1
    " [<tab>]<space><tab>
    " spaces before or between tabs are not allowed
    let t_s_t = '(^\t* +\t\s*\S)'
    " <tab>(<space> x count)
    " count of spaces at the end of tabs should be less than tabstop value
    let t_l_s = '(^\t+ {' . &ts . ',}' . '\S)'
    return search('\v' . t_s_t . '|' . t_l_s, 'nw')
  elseif s:indentation_algorithm == 2
    return search('\v(^\t* +\t\s*\S)', 'nw')
  else
    return search('\v(^\t+ +)|(^ +\t+)', 'nw')
  endif
endfunction

" different indentation in different lines
function! s:check_inconsistent_indentation()
  if index(s:c_like_langs, &ft) > -1
    " for C-like languages: allow /** */ comment style with one space before the '*'
    let head_spc = '\v(^ +\*@!)'
  else
    let head_spc = '\v(^ +)'
  endif
  let indent_tabs = search('\v(^\t+)', 'nw')
  let indent_spc  = search(head_spc, 'nw')
  if indent_tabs > 0 && indent_spc > 0
    if indent_spc < indent_tabs
      return printf("%d:%d", indent_spc, indent_tabs)
    else
      return printf("%d:%d", indent_tabs, indent_spc)
    endif
  else
    return ''
  endif
endfunction

function! lightline#whitespace#check()
  if &readonly || !&modifiable || line('$') > s:max_lines
    return ''
  endif

  let b:result = ""

  if index(get(s:skip_check_ft, &ft, []), 'trailing') < 0
    let trailing = s:check_trailing_whitespaces()
    if trailing != 0
      let b:result .= printf(s:trailing_fmt, trailing)
    endif
  endif

  if index(get(s:skip_check_ft, &ft, []), 'mixed') < 0
    let mixed = s:check_mixed_indentation()
    if mixed != 0
      let b:result .= s:space . printf(s:mixed_fmt, mixed)
    endif
  endif

  if index(get(s:skip_check_ft, &ft, []), 'inconsistent') < 0
    let inconsistent = s:check_inconsistent_indentation()
    if !empty(inconsistent)
      let b:result .= s:space . printf(s:inconsistent_fmt, inconsistent)
    endif
  endif

  return b:result
endfunction
