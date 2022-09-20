%builtins output range_check

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.math import assert_nn

from starkware.cairo.common.registers import get_fp_and_pc

struct Row :
    member row_size : felt
    member row : felt*
end

func wizard{
    output_ptr : felt*,
    range_check_ptr
}(
    array_len : felt, array : Row*
) :
#-> (res : felt):
    alloc_locals
    if array_len == 0:
        return ()
    end
    local arr : Row = [array]
    local size : felt = arr.row_size
    local row : felt* = arr.row

    local sum_v : felt = 0
    let (sum_tmp : felt) = _get_sum_row{
        output_ptr=output_ptr,
        range_check_ptr=range_check_ptr,
        sum_v=sum_v
    }(array=row, size=size)
    serialize_word(sum_tmp)
    return wizard(array_len=array_len - 1, array=array + Row.SIZE)
end

func _get_sum_row{output_ptr : felt*, range_check_ptr, sum_v : felt}(
    array : felt*, size : felt
) -> (sum : felt):  
    alloc_locals

    if size == 0:
        return (sum=sum_v)
    end
    let val = [array]
    #serialize_word(val)
    local new_sum_v : felt = sum_v + val
    assert_nn(new_sum_v)

    return _get_sum_row{output_ptr=output_ptr, range_check_ptr=range_check_ptr, sum_v=new_sum_v}(array = array + 1, size = size - 1)
end

func _output_values{output_ptr : felt*}(
    array : felt*, size : felt
):  
    if size == 0:
        return ()
    end
    let val = [array]
    serialize_word(val)

    return _output_values(array = array + 1, size = size - 1)
end


func main{
    output_ptr: felt*,
    range_check_ptr
}(
):
    alloc_locals
    #local list: (
       #(felt, felt, felt), (felt, felt, felt), (felt, felt, felt)
    #) = ( (2, 7, 6), (9, 5, 1), (4, 3, 8) )

    let (__fp__, _) = get_fp_and_pc()
    #let THREE : felt = 3

    let(local array : Row*) = alloc()
    local list: (
       felt, felt, felt
    ) = (2, 7, 6)
    local list1: (
       felt, felt, felt
    ) = (9, 5, 1)
    local list2: (
       felt, felt, felt
    ) = (4, 3, 8)

    assert [array] = Row(row_size=3, row=cast(&list, felt*))
    assert [array + Row.SIZE] = Row(row_size=3, row=cast(&list1, felt*))
    assert [array + 2 * Row.SIZE] = Row(row_size=3, row=cast(&list2, felt*))

    wizard{
        output_ptr=output_ptr, 
        range_check_ptr=range_check_ptr
    }(
        array_len = 3, array = array
    )
    #let array : felt** = cast(&list, felt**)
    #let val : felt = list[0][1]
    
    #serialize_word(val)
    return ()
end