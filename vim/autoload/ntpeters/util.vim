
" Checks whether a given Python module is installed¬
function! ntpeters#util#hasPythonModule(name)
    let a:hasModule = 0
    if has('python3')
python3 << moduleCheck
import vim, pkgutil
if pkgutil.find_loader(vim.eval("a:name")):
    vim.command("let a:hasModule = 1")
moduleCheck
    endif
    return a:hasModule
endfunction

" Use with Plug to conditionally load plugins
" This allows the plugin to be registered even if not used, to prevent
" potential removal
function! ntpeters#util#plugEnableIf(condition, ...)
    let opts = get(a:000, 0, {})
    return a:condition ? opts : extend(opts, { 'on': [], 'for': [] })
endfunction

