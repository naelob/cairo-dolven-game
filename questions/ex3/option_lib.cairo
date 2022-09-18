%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
)

############
# EVENTS
############

@event 
func NftDeposited(sender : felt, underlying : felt, token_id : felt):
end

@event 
func OptionPurchased(buyer : felt)
end

@event 
func OptionExercised(caller : felt):
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

#ERC20 (likely a stablecoin) in which the premium & strike is denominated
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

@storage_var
func quote_token() -> (token: felt) :
end


namespace Option:

    
    func deposit{
    }(underlying : felt, token_id : felt):
        _only_seller()
        let (bool) = is_nft_deposited.read()
        with_attr error_message("Already deposited"):
            assert bool = FALSE
        end

        is_nft_deposited.write(TRUE)
        underlying_nft.write(underlying)
        underlying_token_id.write(token_id)

        #todo
        IERC721()

        let (caller) = get_caller_address()
        NftDeposited.emit(caller, underlying, token_id)
    end

    func purchase_call_option{}():
        let (buyer) = buyer.read()
        with_attr error_message("Option already purchased"):
            assert buyer = 0
        end

        let (bool) = is_nft_deposited.read()
        with_attr error_message("No NFT deposited yet"):
            assert bool = TRUE
        end

        let (caller) = get_caller_address()
        let (seller) = seller.read()
        let (premium) = premium.read()
        # transfer premium to seller
        IERC20().safeTransferFrom(caller, seller, premium)
        buyer.write(caller)
        OptionPurchased.emit(caller)
    end

    func exercise_option{}():
        let (timestamp) = get_block_timestamp()
        let (expiry) = expiry.read()
        with_attr error_message("Option expired"):
            let (res) = assert_lt(timestamp, expiry)
            assert res = 1
        end

        let (strike) = strike.read()
        # transfer strike to seller
        IERC20().safeTransferFrom(caller, seller, strike)

        let (contract_address) = get_contract_address()
        let (token_id) = underlying_token_id.read()

        #Transfer underlying NFT to the buyer
        IERC721().safeTransferFrom(contract_address, caller, token_id)

        let (caller) = get_caller_address()
        OptionExercised.emit(caller);
    end


end

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