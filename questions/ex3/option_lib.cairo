%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp
)

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.uint256 import (
    Uint256, 
    split_64
)

from starkware.cairo.common.math import (
    assert_not_equal,
    assert_lt,
    assert_not_zero,
)

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address
)

from starkware.cairo.common.bool import TRUE, FALSE


from openzeppelin.token.erc20 import IERC20
from openzeppelin.token.erc721 import IERC721


############
# EVENTS
############

@event 
func NftDeposited(sender : felt, underlying : felt, token_id : felt):
end

@event 
func OptionPurchased(buyer : felt):
end

@event 
func OptionExercised(caller : felt):
end

@event 
func OptionClosed(seller : felt):
end


############
# STORAGE
############

@storage_var
func seller() -> (address: felt) :
end

@storage_var
func buyer() -> (address: felt) :
end

@storage_var
func underlying_nft() -> (address: felt) :
end

@storage_var
func underlying_token_id() -> (id: felt) :
end

@storage_var
func is_nft_deposited() -> (bool: felt) :
end

#ERC20 (likely a stablecoin) in which the premium & strike are denominated
@storage_var
func quote_token() -> (token: felt) :
end

@storage_var
func strike() -> (res: felt) :
end

@storage_var
func premium() -> (res: felt) :
end

@storage_var
func expiry() -> (res: felt) :
end

const TOKEN = 0x097667676776
const NFT = 0x097667676776


namespace Option:
    
    func deposit{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(underlying : felt, token_id : felt):
        with_attr error_message("Already deposited"):
            let (bool) = is_nft_deposited.read()
            assert bool = FALSE
        end

        is_nft_deposited.write(TRUE)
        underlying_nft.write(underlying)
        underlying_token_id.write(token_id)

        let (caller) = get_caller_address()
        let (contract_address) = get_contract_address()

        let (low, high) = split_64(token_id)
        let token_id = Uint256(low, high)

        IERC721.transferFrom(contract_address=NFT, from_=caller, to=contract_address, tokenId=token_id)

        NftDeposited.emit(caller, underlying, token_id)
    end

    func purchase_call_option{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }():
        let (buyer) = buyer.read()
        with_attr error_message("Option already purchased"):
            assert_not_zero(buyer)
        end

        with_attr error_message("No NFT deposited yet"):
            let (bool) = is_nft_deposited.read()
            assert bool = TRUE
        end

        let (caller) = get_caller_address()
        let (seller) = seller.read()
        let (premium) = premium.read()
        
        # transfer premium to seller
        let (success) = IERC20.transferFrom(contract_address=TOKEN, sender=caller, recipient=seller, amount=premium)

        with_attr error_message("transfer failed"):
            assert success = TRUE
        end

        buyer.write(caller)

        OptionPurchased.emit(caller)
    end

    func exercise_option{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }():

        let (timestamp) = get_block_timestamp()
        let (expiry) = expiry.read()
        with_attr error_message("Option expired"):
            assert_lt(timestamp, expiry)
        end

        let (strike) = strike.read()
        # transfer strike to seller
        let (success) = IERC20.transferFrom(contract_address=TOKEN, sender=caller, recipient=seller, amount=strike)

        with_attr error_message("transfer failed"):
            assert success = TRUE
        end

        let (contract_address) = get_contract_address()
        
        let (token_id) = underlying_token_id.read()
        let (low, high) = split_64(tokenId)
        let _token_id = Uint256(low, high)

        #Transfer underlying NFT to the buyer
        IERC721.transferFrom(contract_address=NFT, from_=contract_address, to=caller, tokenId=_token_id)
        let (caller) = get_caller_address()
        OptionExercised.emit(caller)
    end

    func close_option{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }():
        let (timestamp) = get_block_timestamp()
        let (expiry) = expiry.read()
        
        with_attr error_message("Option has not expired yet (1)"):
            assert_lt(expiry, timestamp)
        end 
        
        let (buyer) = buyer.read()
        with_attr error_message("Option has not expired yet (2)"):
            assert buyer = 0
        end 

        #Transfer NFT back to seller
        let (contract_address) = get_contract_address()
        let (caller) = get_caller_address()
        
        let (token_id) = underlying_token_id.read()
        let (low, high) = split_64(tokenId)
        let _token_id  = Uint256(low, high)

        IERC721.transferFrom(contract_address=NFT, from_=contract_address, to=caller, tokenId=_token_id)

        is_nft_deposited.write(FALSE)

        OptionClosed.emit(caller)
    end

    func get_underlying{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (res : felt):
        let (res) = underlying_nft.read()
        return (res=res)
    end

    func get_underlying_token_id{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (res : felt):
        let (res) = underlying_token_id.read()
        return (res=res)
    end

    func get_strike{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (res : felt):
        let (res) = strike.read()
        return (res=res)
    end

    func get_expiry{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (res : felt):
        let (res) = expiry.read()
        return (res=res)
    end

    func get_premium{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (res : felt):
        let (res) = premium.read()
        return (res=res)
    end

    func get_quote_token{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (res : felt):
        let (res) = quote_token.read()
        return (res=res)
    end

    func get_if_nft_deposited{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (res : felt):
        let (res) = is_nft_deposited.read()
        return (res=res)
    end

    func get_seller{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (res : felt):
        let (res) = seller.read()
        return (res=res)
    end

    func get_buyer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (res : felt):
        let (res) = buyer.read()
        return (res=res)
    end
end