// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {PolygonChildERC20Upgradeable} from "./abstracts/PolygonChildERC20Upgradeable.sol";
import {OptimismERC20Upgradeable} from "./abstracts/OptimismERC20Upgradeable.sol";
import {ArbitrumERC20Upgradeable} from "./abstracts/ArbitrumERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AltInsureTokenV1 is
    ERC20Upgradeable,
    OwnableUpgradeable,
    OptimismERC20Upgradeable,
    ArbitrumERC20Upgradeable,
    PolygonChildERC20Upgradeable
{
    struct Supply {
        uint256 cap;
        uint256 total;
    }

    mapping(address => Supply) public bridges;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _l1Token,
        address _childChainManagerProxy,
        address _l2Gateway
    ) public virtual initializer {
        __ERC20_init("alt insure token", "INSURE");
        __Ownable_init();
        __PolygonChildERC20_init(_childChainManagerProxy);
        __OptimismERC20_init(_l1Token);
        __ArbitrumERC20_init(_l2Gateway, _l1Token);
    }

    function mint(address _to, uint256 _amount) external override {
        Supply storage bridgeSupply = bridges[msg.sender];
        if (bridgeSupply.cap < 0) revert NotAllowedBridger();
        bridgeSupply.total += _amount;
        if (bridgeSupply.total > bridgeSupply.cap) revert ExceedSupplyCap();
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
    }

    function burn(address _from, uint256 _amount) external override {
        _burn(_from, _amount);
    }

    function _burnFrom(address _from, uint256 _amount) internal {
        Supply storage bridgeSupply = bridges[msg.sender];
        if (bridgeSupply.cap > 0 || bridgeSupply.total > 0) {
            if (bridgeSupply.total < _amount) revert BurnAmountExceeded();
            unchecked {
                bridgeSupply.total -= _amount;
            }
        }
        _spendAllowance(_from, msg.sender, _amount);
        _burn(_from, _amount);
    }

    function updateBridgeSupplyCap(address _bridge, uint256 _cap)
        external
        onlyOwner
    {
        bridges[_bridge].cap = _cap;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(AccessControlUpgradeable, OptimismERC20Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}

error NotAllowedBridger();
error ExceedSupplyCap();
error BurnAmountExceeded();
