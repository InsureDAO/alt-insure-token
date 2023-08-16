// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {OptimismERC20Upgradeable} from "./abstracts/OptimismERC20Upgradeable.sol";
import {ArbitrumERC20Upgradeable} from "./abstracts/ArbitrumERC20Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {IArbToken} from "./interfaces/IArbToken.sol";
import {IOptimismStandardERC20} from "./interfaces/IOptimismStandardERC20.sol";

import {AltInsureTokenBase} from "./abstracts/AltInsureTokenBase.sol";

contract AltInsureTokenV1 is
    AltInsureTokenBase,
    OptimismERC20Upgradeable,
    ArbitrumERC20Upgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _l1Token,
        address _childChainManagerProxy,
        address _l2Gateway
    ) public virtual initializer {
        __AltInsureBase_init(_childChainManagerProxy);
        __OptimismERC20_init(_l1Token);
        __ArbitrumERC20_init(_l2Gateway, _l1Token);
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, AltInsureTokenBase)
        returns (address _sender)
    {
        return AltInsureTokenBase._msgSender();
    }

    /**
     * public functions
     */

    /// @inheritdoc AltInsureTokenBase
    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        virtual
        override(IERC20Upgradeable, ERC20Upgradeable, AltInsureTokenBase)
        returns (bool)
    {
        return AltInsureTokenBase.transferFrom(from, to, amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) public virtual override(OptimismERC20Upgradeable, AltInsureTokenBase) {
        super.mint(_to, _amount);
    }

    function burn(
        address _from,
        uint256 _amount
    ) public virtual override(OptimismERC20Upgradeable, AltInsureTokenBase) {
        super.burn(_from, _amount);
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(IERC165Upgradeable, AltInsureTokenBase)
        returns (bool)
    {
        return
            AltInsureTokenBase.supportsInterface(_interfaceId) ||
            _interfaceId == type(IOptimismStandardERC20).interfaceId ||
            _interfaceId == type(IArbToken).interfaceId;
    }
}

error NotAllowedBridger();
error ExceedSupplyCap();
error BurnAmountExceeded();
