" Misc utility functions used in my vimrc

" Get null output stream path based on platform
function! ntpeters#util#devNullPath()
    if has('win32')
        return 'NUL'
    else
        return '/dev/null'
    endif
endfunction

" Creates the given directory if it doesn't exist
function! ntpeters#util#ensureDirectory(path)
    let l:expandedPath = expand(a:path)
    let l:devNull = ntpeters#util#devNullPath()
    if empty(glob(l:expandedPath))
        :silent execute '!mkdir -p ' . l:expandedPath . ' > ' . l:devNull . ' 2>&1'
    endif
endfunction

" Downloads a file at the given URI to the specified path
function! ntpeters#util#downloadFile(uri, path)
    let l:expandedPath = expand(a:path)

    if has('win32')
        let l:targetDirectory = fnamemodify(l:expandedPath, ":h")
        call ntpeters#util#ensureDirectory(l:targetDirectory)
        :silent execute '!powershell -Command Invoke-WebRequest -Uri ' . a:uri . ' -OutFile ' . l:expandedPath
    else
        :silent execute '!curl -fLo ' . l:expandedPath . ' --create-dirs ' . a:uri
    endif
endfunction

" Downloads Plug if not installed, and installs all plugins
function! ntpeters#util#ensurePlug()
    let l:plugPath = '~/.vim/autoload/plug.vim'
    let l:plugUrl = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    if empty(glob(l:plugPath))
       call ntpeters#util#downloadFile(l:plugUrl, l:plugPath)
       autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    endif
endfunction

" Checks whether a given Python module is installed
function! ntpeters#util#hasPythonModule(name)
    let l:hasModule = 0
    if has('pythonx')
pythonx << moduleCheck
import vim, pkgutil
if pkgutil.find_loader(vim.eval("a:name")):
    vim.command("let l:hasModule = 1")
moduleCheck
    endif
    return l:hasModule
endfunction

" Use with Plug to conditionally load plugins
" This allows the plugin to be registered even if not used, to prevent
" potential removal
function! ntpeters#util#plugEnableIf(condition, ...)
    let opts = get(a:000, 0, {})
    return a:condition ? opts : extend(opts, { 'on': [], 'for': [] })
endfunction

" Attempt setting a colorscheme and swallow errors if it doesn't exist
function! ntpeters#util#tryColorscheme(name)
    try
        exe "colorscheme " . a:name
    endtry
endfunction

" Toggles between tabs and spaces for the current buffer
function! ntpeters#util#toggleTabs()
    set expandtab!
    retab!
endfunction

function! ntpeters#util#isTempDir(path)
    " Some platforms (Windows) use TMP
    if len($TMP) && a:path == $TMP
        return 1
    endif

    " Some platforms (Windows) use TEMP
    if len($TEMP) && a:path == $TEMP
        return 1
    endif

    " Linux/macOS use TMPDIR
    if len($TMPDIR) && a:path == $TMPDIR
        return 1
    endif

    " Some distros use XDG_RUNTIME_DIR, a per-user temp space
    if len($XDG_RUNTIME_DIR ) && a:path == $XDG_RUNTIME_DIR
        return 1
    endif

    return 0
endfunction

function! ntpeters#util#shouldRestoreView()
    " Only save/load views for normal files
    if !empty(&buftype)
        return 0
    endif

    " Only save/load views for existing files
    if !filereadable(expand('%:p'))
        return 0
    endif

    " Don't save/load views for files in a temp dir
    if ntpeters#util#isTempDir(expand('%:p:h'))
        return 0
    endif

    return 1
endfunction
