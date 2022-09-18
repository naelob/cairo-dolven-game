%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
)

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.math import (
    assert_not_equal,
    assert_lt,
    assert_not_zero
)

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address
)

from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc20.library import ERC20

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
func underlying_token_id() -> (id: Uint256) :
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
        #_only_seller()
        with_attr error_message("Already deposited"):
            let (bool) = is_nft_deposited.read()
            assert bool = FALSE
        end

        is_nft_deposited.write(TRUE)
        underlying_nft.write(underlying)
        underlying_token_id.write(token_id)

        let (caller) = get_caller_address()
        let (contract_address) = get_contract_address()
        ERC721.transferFrom(caller,contract_address, token_id)

        NftDeposited.emit(caller, underlying, token_id)
    end

    func purchase_call_option{}():
        let (buyer) = buyer.read()
        with_attr error_message("Option already purchased"):
            let (res) = assert_not_zero(buyer)
            assert res = 0
        end

        with_attr error_message("No NFT deposited yet"):
            let (bool) = is_nft_deposited.read()
            assert bool = TRUE
        end

        let (caller) = get_caller_address()
        let (seller) = seller.read()
        let (premium) = premium.read()
        
        # transfer premium to seller
        let (success) = ERC20.transferFrom(caller, seller, premium)

        with_attr error_message("transfer failed"):
            assert success = 1
        end

        buyer.write(caller)
        OptionPurchased.emit(caller)
    end

    func exercise_option{}():
        #_only_buyer()

        let (timestamp) = get_block_timestamp()
        let (expiry) = expiry.read()
        with_attr error_message("Option expired"):
            let (res) = assert_lt(timestamp, expiry)
            assert res = 1
        end

        let (strike) = strike.read()
        # transfer strike to seller
        let (success) = ERC20.transferFrom(caller, seller, strike)

        with_attr error_message("transfer failed"):
            assert success = 1
        end

        let (contract_address) = get_contract_address()
        let (token_id) = underlying_token_id.read()

        #Transfer underlying NFT to the buyer
        ERC721.transferFrom(contract_address, caller, token_id)

        let (caller) = get_caller_address()
        OptionExercised.emit(caller);
    end

    func close_option{}():
        #_only_seller()
        let (timestamp) = get_block_timestamp()
        let (expiry) = expiry.read()
        
        with_attr error_message("Option has not expired yet (1)"):
            let (res) = assert_lt(expiry, timestamp)
            assert res = 1
        end 
        
        let (buyer) = buyer.read()
        with_attr error_message("Option has not expired yet (2)"):
            let (res) = assert_not_zero(buyer)
            assert res = 0
        end 

        #Transfer NFT back to seller
        let (contract_address) = get_contract_address()
        let (caller) = get_caller_address()
        let (token_id) = underlying_token_id.read()
        ERC721.transferFrom(contract_address, caller, token_id);
        is_nft_deposited.write(FALSE)

        OptionClosed.emit(caller)
    end


end

#func _only_seller{}():
    #with_attr error_message("only seller can deposit NFT"):
     #   let (caller) = get_caller_address()
     #   let (seller) = seller.read()
     #   let (res) = assert_not_equal(caller, seller)
     #  assert res = 0
    #end
#end

#func _only_buyer{}():
  #  with_attr error_message("only buyer can exercise Option"):
  #      let (caller) = get_caller_address()
  #      let (buyer) = buyer.read()
  #      let (res) = assert_not_equal(caller, buyer)
  #      assert res = 0
  #  end
#end