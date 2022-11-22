// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {OptimismERC20Upgradeable} from "./abstracts/OptimismERC20Upgradeable.sol";
import {ArbitrumERC20Upgradeable} from "./abstracts/ArbitrumERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

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

    /**
     * public functions
     */

    function mint(address _to, uint256 _amount)
        public
        virtual
        override(OptimismERC20Upgradeable, AltInsureTokenBase)
    {
        super.mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount)
        public
        virtual
        override(OptimismERC20Upgradeable, AltInsureTokenBase)
    {
        super.burn(_from, _amount);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        pure
        virtual
        override(IERC165Upgradeable, AltInsureTokenBase)
        returns (bool)
    {
        bytes4 optimismStandardInterface = IOptimismStandardERC20
            .l1Token
            .selector ^
            IOptimismStandardERC20.mint.selector ^
            IOptimismStandardERC20.burn.selector;

        bytes4 arbitrumStandardInterface = IArbToken.l1Address.selector ^
            IArbToken.bridgeMint.selector ^
            IArbToken.bridgeBurn.selector;

        return
            super.supportsInterface(_interfaceId) ||
            _interfaceId == optimismStandardInterface ||
            _interfaceId == arbitrumStandardInterface;
    }
}

error NotAllowedBridger();
error ExceedSupplyCap();
error BurnAmountExceeded();
