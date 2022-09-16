%builtins output


func print_to_console{output_ptr: felt*}(value : felt):
    assert [output_ptr] = value
    let output_ptr = output_ptr + 1
    return ()
end

func main{output_ptr: felt*}():
    alloc_locals
    local start_output_ptr : felt* = output_ptr
    
    let x = 9
    let y = x * 23
    print_to_console(value=y)
    assert output_ptr = start_output_ptr + 1
    return ()
end