functions_root="${${(%):-%x}:A:h}"


for func in ${functions_root}/*; do
    local func_name="$(basename $func)"
    autoload -U "$func_name"
done
unset func
