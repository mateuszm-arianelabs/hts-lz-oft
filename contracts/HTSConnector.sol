// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.22;

import {OFTCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import "./hts/HederaTokenService.sol";
import "./hts/IHederaTokenService.sol";
import "./hts/KeyHelper.sol";

/**
 * @title HTS Connector
 * @dev HTS Connector is a HTS token that extends the functionality of the OFTCore contract.
    */
abstract contract HTSConnector is OFTCore, KeyHelper, HederaTokenService {
    address public htsTokenAddress;
    bool public finiteTotalSupplyType = true;
    event TokenCreated(address tokenAddress);

    /**
     * @dev Constructor for the HTS Connector contract.
     * @param _name The name of HTS token
     * @param _symbol The symbol of HTS token
     * @param _lzEndpoint The LayerZero endpoint address.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) payable OFTCore(8, _lzEndpoint, _delegate) {
        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](1);
        keys[0] = getSingleKey(
            KeyType.SUPPLY,
            KeyValueType.INHERIT_ACCOUNT_KEY,
            bytes("")
        );

        IHederaTokenService.Expiry memory expiry = IHederaTokenService.Expiry(0, address(this), 8000000);
        IHederaTokenService.HederaToken memory token = IHederaTokenService.HederaToken(
            _name, _symbol, address(this), "memo", finiteTotalSupplyType, 5000, false, keys, expiry
        );

        (int responseCode, address tokenAddress) = HederaTokenService.createFungibleToken(
            token, 1000, int32(int256(uint256(8)))
        );
        require(responseCode == HederaTokenService.SUCCESS_CODE, "Failed to create HTS token");

        int256 transferResponse = HederaTokenService.transferToken(tokenAddress, address(this), msg.sender, 1000);
        require(transferResponse == HederaTokenService.SUCCESS_CODE, "HTS: Transfer failed");

        htsTokenAddress = tokenAddress;

        emit TokenCreated(tokenAddress);
    }

    /**
     * @dev Retrieves the address of the underlying HTS implementation.
     * @return The address of the HTS token.
     */
    function token() public view returns (address) {
        return htsTokenAddress;
    }

    /**
     * @notice Indicates whether the HTS Connector contract requires approval of the 'token()' to send.
     * @return requiresApproval Needs approval of the underlying token implementation.
     */
    function approvalRequired() external pure virtual returns (bool) {
        return false;
    }

    /**
     * @dev Burns tokens from the sender's specified balance.
     * @param _from The address to debit the tokens from.
     * @param _amountLD The amount of tokens to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @param _dstEid The destination chain ID.
     * @return amountSentLD The amount sent in local decimals.
     * @return amountReceivedLD The amount received in local decimals on the remote.
     */
    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        require(_amountLD <= uint64(type(int64).max), "HTSConnector: amount exceeds int64 safe range");

        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

        int256 transferResponse = HederaTokenService.transferToken(htsTokenAddress, _from, address(this), int64(uint64(_amountLD)));
        require(transferResponse == HederaTokenService.SUCCESS_CODE, "HTS: Transfer failed");

        (int256 response,) = HederaTokenService.burnToken(htsTokenAddress, int64(uint64(amountSentLD)), new int64[](0));
        require(response == HederaTokenService.SUCCESS_CODE, "HTS: Burn failed");
    }

    /**
     * @dev Credits tokens to the specified address.
     * @param _to The address to credit the tokens to.
     * @param _amountLD The amount of tokens to credit in local decimals.
     * @dev _srcEid The source chain ID.
     * @return amountReceivedLD The amount of tokens ACTUALLY received in local decimals.
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 /*_srcEid*/
    ) internal virtual override returns (uint256) {
        require(_amountLD <= uint64(type(int64).max), "HTSConnector: amount exceeds int64 safe range");

        (int256 response, ,) = HederaTokenService.mintToken(htsTokenAddress, int64(uint64(_amountLD)), new bytes[](0));
        require(response == HederaTokenService.SUCCESS_CODE, "HTS: Mint failed");

        int256 transferResponse = HederaTokenService.transferToken(htsTokenAddress, address(this), _to, int64(uint64(_amountLD)));
        require(transferResponse == HederaTokenService.SUCCESS_CODE, "HTS: Transfer failed");

        return _amountLD;
    }
}