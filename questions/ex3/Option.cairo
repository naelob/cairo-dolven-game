%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from option_lib import (
    Option,
    seller, quote_token, expiry, strike
)

from starkware.cairo.common.math import (
    assert_not_equal,
)

from starkware.starknet.common.syscalls import (
    get_caller_address,
)

from starkware.cairo.common.uint256 import Uint256



############
#  VIEW 
############

@view
func get_underlying{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}() -> (res : felt):
    let (res) = Option.get_underlying()
    return (res=res)
end

@view
func get_underlying_token_id{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}() -> (res : felt):
    let (res) = Option.get_underlying_token_id()
    return (res=res)
end

@view
func get_seller{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}() -> (res : felt):
    let (res) = Option.get_underlying()
    return (res=res)
end

@view
func get_buyer{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}() -> (res : felt):
    let (res) = Option.get_buyer()
    return (res=res)
end

@view
func get_if_nft_deposited{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}() -> (res : felt):
    let (res) = Option.get_if_nft_deposited()
    return (res=res)
end

@view
func get_quote_token{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}() -> (res : felt):
    let (res) = Option.get_quote_token()
    return (res=res)
end

@view
func get_strike{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}() -> (res : felt):
    let (res) = Option.get_strike()
    return (res=res)
end

@view
func get_premium{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}() -> (res : felt):
    let (res) = Option.get_premium()
    return (res=res)
end

@view
func get_expiry{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}() -> (res : felt):
    let (res) = Option.get_expiry()
    return (res=res)
end


############
# CONSTRUCTOR
############
@constructor
func constructor{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}(
    _quote_token : felt, _strike : felt, _premium : felt, _expiry : felt
):
    let (caller) = get_caller_address()
    seller.write(caller)
    quote_token.write(_quote_token)
    premium.write(_premium)
    strike.write(_strike)
    expiry.write(_expiry)
    return ()
end

############
# EXTERNAL
############

@external
func deposit{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}(underlying : felt, token_id : felt):
    _only_seller()
    Option.deposit()
    return ()
end

@external
func purchase_call_option{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}():
    Option.purchase_call_option()
    return ()
end

@external
func exercise_option{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}():
    _only_buyer()
    Option.exercise_option()
    return ()
end

@external
func close_option{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}():
    _only_seller()
    Option.close_option()
    return ()
end


############
# MODIFIER
############

func _only_seller{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}():
    with_attr error_message("only seller can deposit NFT"):
        let (caller) = get_caller_address()
        let (seller) = seller.read()
        assert_not_equal(caller, seller)
    end
end

func _only_buyer{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr
}():
    with_attr error_message("only buyer can exercise Option"):
        let (caller) = get_caller_address()
        let (buyer) = buyer.read()
        assert_not_equal(caller, buyer)
    end
end

