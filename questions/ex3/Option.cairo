%lang starknet

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


############
#  VIEW 
############


############
# CONSTRUCTOR
############
@constructor
func constructor{
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
}(underlying : felt, token_id : felt):
    _only_seller()
    Option.deposit()
    return ()
end

@external
func purchase_call_option{}():
    Option.purchase_call_option()
    return ()
end

@external
func exercise_option{}():
    _only_buyer()
    Option.exercise_option()
    return ()
end

@external
func close_option{}():
    _only_seller()
    Option.close_option()
    return ()
end


############
# MODIFIER
############

func _only_seller{}():
    with_attr error_message("only seller can deposit NFT"):
        let (caller) = get_caller_address()
        let (seller) = seller.read()
        let (res) = assert_not_equal(caller, seller)
        assert res = 0
    end
end

func _only_buyer{}():
    with_attr error_message("only buyer can exercise Option"):
        let (caller) = get_caller_address()
        let (buyer) = buyer.read()
        let (res) = assert_not_equal(caller, buyer)
        assert res = 0
    end
end

