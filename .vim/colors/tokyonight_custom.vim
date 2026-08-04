" tokyonight_custom.vim — Fallback colorscheme using exact tmux palette
" Palette from ~/.tmux.conf:
"   bg_dark  #1a1b26    fg       #a9b1d6
"   bg_mid   #24283b    blue     #7aa2f7
"   bg_light #414868    cyan     #7dcfff
"                        green    #9ece6a
"                        yellow   #e0af68
"                        red      #f7768e

set background=dark
hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'tokyonight_custom'

" ── UI Elements ─────────────────────────────────────────────────
hi Normal       guifg=#a9b1d6 guibg=#1a1b26 ctermfg=146 ctermbg=234
hi NormalFloat  guifg=#a9b1d6 guibg=#24283b ctermfg=146 ctermbg=235
hi Cursor       guifg=#1a1b26 guibg=#a9b1d6 ctermfg=234 ctermbg=146
hi CursorLine   guibg=#24283b ctermbg=235   cterm=NONE gui=NONE
hi CursorLineNr guifg=#7aa2f7 guibg=#24283b ctermfg=111 ctermbg=235 gui=bold
hi LineNr       guifg=#414868 guibg=#1a1b26 ctermfg=59  ctermbg=234
hi SignColumn   guifg=#414868 guibg=#1a1b26 ctermfg=59  ctermbg=234
hi ColorColumn  guibg=#24283b ctermbg=235
hi VertSplit    guifg=#414868 guibg=#1a1b26 ctermfg=59  ctermbg=234
hi StatusLine   guifg=#a9b1d6 guibg=#24283b ctermfg=146 ctermbg=235 gui=bold
hi StatusLineNC guifg=#414868 guibg=#1a1b26 ctermfg=59  ctermbg=234 gui=NONE
hi TabLine      guifg=#414868 guibg=#1a1b26 ctermfg=59  ctermbg=234
hi TabLineFill  guifg=#414868 guibg=#1a1b26 ctermfg=59  ctermbg=234
hi TabLineSel   guifg=#1a1b26 guibg=#7aa2f7 ctermfg=234 ctermbg=111 gui=bold
hi Folded       guifg=#7aa2f7 guibg=#24283b ctermfg=111 ctermbg=235
hi FoldColumn   guifg=#414868 guibg=#1a1b26 ctermfg=59  ctermbg=234
hi Pmenu        guifg=#a9b1d6 guibg=#24283b ctermfg=146 ctermbg=235
hi PmenuSel     guifg=#1a1b26 guibg=#7aa2f7 ctermfg=234 ctermbg=111
hi PmenuSbar    guibg=#24283b ctermbg=235
hi PmenuThumb   guibg=#414868 ctermbg=59
hi WildMenu     guifg=#1a1b26 guibg=#7aa2f7 ctermfg=234 ctermbg=111 gui=bold
hi Visual       guibg=#364a82 ctermbg=60
hi VisualNOS    guibg=#364a82 ctermbg=60

" ── Search & Matching ───────────────────────────────────────────
hi Search       guifg=#1a1b26 guibg=#e0af68 ctermfg=234 ctermbg=179
hi IncSearch    guifg=#1a1b26 guibg=#ff9e64 ctermfg=234 ctermbg=209 gui=bold
hi MatchParen   guifg=#ff9e64 guibg=NONE    ctermfg=209 cterm=bold gui=bold

" ── Messages ────────────────────────────────────────────────────
hi ErrorMsg     guifg=#f7768e guibg=NONE ctermfg=204
hi WarningMsg   guifg=#e0af68 guibg=NONE ctermfg=179
hi MoreMsg      guifg=#9ece6a guibg=NONE ctermfg=150
hi Question     guifg=#7dcfff guibg=NONE ctermfg=117
hi Title        guifg=#7aa2f7 guibg=NONE ctermfg=111 gui=bold
hi Directory    guifg=#7aa2f7 guibg=NONE ctermfg=111

" ── Diff ────────────────────────────────────────────────────────
hi DiffAdd    guibg=#20303b ctermbg=236
hi DiffChange guibg=#1f2231 ctermbg=235
hi DiffDelete guifg=#f7768e guibg=#37222c ctermfg=204 ctermbg=52
hi DiffText   guibg=#394b70 ctermbg=60    gui=bold

" ── Diagnostics ─────────────────────────────────────────────────
hi SpellBad   guisp=#f7768e gui=undercurl ctermfg=204 cterm=underline
hi SpellCap   guisp=#e0af68 gui=undercurl ctermfg=179 cterm=underline
hi SpellRare  guisp=#bb9af7 gui=undercurl ctermfg=141 cterm=underline
hi SpellLocal guisp=#7dcfff gui=undercurl ctermfg=117 cterm=underline

" ── Syntax Groups ───────────────────────────────────────────────
hi Comment    guifg=#565f89 ctermfg=60  gui=italic
hi Constant   guifg=#ff9e64 ctermfg=209
hi String     guifg=#9ece6a ctermfg=150
hi Character  guifg=#9ece6a ctermfg=150
hi Number     guifg=#ff9e64 ctermfg=209
hi Boolean    guifg=#ff9e64 ctermfg=209
hi Float      guifg=#ff9e64 ctermfg=209
hi Identifier guifg=#c0caf5 ctermfg=153
hi Function   guifg=#7aa2f7 ctermfg=111
hi Statement  guifg=#bb9af7 ctermfg=141
hi Keyword    guifg=#bb9af7 ctermfg=141
hi Operator   guifg=#89ddff ctermfg=117
hi PreProc    guifg=#7dcfff ctermfg=117
hi Include    guifg=#7dcfff ctermfg=117
hi Type       guifg=#2ac3de ctermfg=44
hi StorageClass guifg=#bb9af7 ctermfg=141
hi Structure  guifg=#7aa2f7 ctermfg=111
hi Special    guifg=#7dcfff ctermfg=117
hi SpecialChar guifg=#ff9e64 ctermfg=209
hi Delimiter  guifg=#a9b1d6 ctermfg=146
hi Tag        guifg=#f7768e ctermfg=204
hi Underlined guifg=#7aa2f7 ctermfg=111 gui=underline
hi Error      guifg=#f7768e guibg=NONE  ctermfg=204
hi Todo       guifg=#e0af68 guibg=NONE  ctermfg=179 gui=bold
hi NonText    guifg=#414868 ctermfg=59
hi SpecialKey guifg=#414868 ctermfg=59
hi Conceal    guifg=#414868 ctermfg=59

" ── ALE Diagnostics ─────────────────────────────────────────────
hi ALEError      guifg=#f7768e gui=undercurl guisp=#f7768e ctermfg=204 cterm=underline
hi ALEWarning    guifg=#e0af68 gui=undercurl guisp=#e0af68 ctermfg=179 cterm=underline
hi ALEErrorSign  guifg=#f7768e guibg=#1a1b26 ctermfg=204 ctermbg=234
hi ALEWarningSign guifg=#e0af68 guibg=#1a1b26 ctermfg=179 ctermbg=234
