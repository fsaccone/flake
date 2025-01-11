  " Table of contents:
"   1. General
"   2. Interface
"   3. Appearence
"   4. Files
"   5. Indentation
"   6. Status line

" 1. General
set shell=bash

set nocompatible
set history=5

filetype plugin on
filetype indent on

set autoread
au FocusGained,BufEnter * silent! checktime

" 2. Interface
set scrolloff=0
set sidescrolloff=0
set startofline
set foldcolumn=2

set wildmenu
set showmode
set noruler
set number

set mouse=
set backspace=indent,start

set smartcase
set hlsearch
set incsearch
set lazyredraw
set magic
set noshowmatch

set noerrorbells
set novisualbell

set noequalalways

" 3. Appearence
syntax enable

set encoding=utf8

set cursorline
set number

" 4. Files
set nobackup
set nowriteany
set noswapfile

" 5. Indentation
set expandtab
set shiftwidth=2
set tabstop=2

set nolinebreak

set autoindent
set smartindent
set nowrap

" 6. Status line
set laststatus=2
set statusline=
set statusline+=\|\ %=
set statusline+=\ %F
set statusline+=\ %h
set statusline+=%r
set statusline+=%m
set statusline+=\ \|\ %l:%c
set statusline+=\ \|
