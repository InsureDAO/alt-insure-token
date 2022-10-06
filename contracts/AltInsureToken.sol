// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PolygonChildERC20} from "./abstracts/PolygonChildERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {ERC2771ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

contract AltInsureTokenV1 is
    ERC20Upgradeable,
    PolygonChildERC20,
    OwnableUpgradeable
{
    struct Supply {
        uint256 cap;
        uint256 total;
    }

    mapping(address => Supply) public bridges;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _childChainManagerProxy)
        public
        virtual
        initializer
    {
        __ERC20_init("alt insure token", "INSURE");
        __PolygonChildERC20_init(_childChainManagerProxy);
        __Ownable_init();
    }

    function mint(address _to, uint256 _amount) external returns (bool) {
        Supply storage bridgeSupply = bridges[msg.sender];
        if (bridgeSupply.cap < 0) revert NotAllowedBridger();
        bridgeSupply.total += _amount;
        if (bridgeSupply.total > bridgeSupply.cap) revert ExceedSupplyCap();
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) external returns (bool) {
        _burn(_msgSender(), _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external returns (bool) {}

    function _burnFrom(address _from, uint256 _amount) internal returns (bool) {
        Supply storage bridgeSupply = bridges[msg.sender];
        if (bridgeSupply.cap > 0 || bridgeSupply.total > 0) {
            if (bridgeSupply.total < _amount) revert BurnAmountExceeded();
            unchecked {
                bridgeSupply.total -= _amount;
            }
        }
        _spendAllowance(_from, msg.sender, _amount);
        _burn(_from, _amount);
        return true;
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
}

error NotAllowedBridger();
error ExceedSupplyCap();
error BurnAmountExceeded();
