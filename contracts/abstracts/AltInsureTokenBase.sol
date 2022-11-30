// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

import {PolygonChildERC20Upgradeable} from "./PolygonChildERC20Upgradeable.sol";

import {IPolygonChildERC20} from "../interfaces/IPolygonChildERC20.sol";
import {ICelerBridgeTokenV1} from "../interfaces/ICelerBridgeTokenV1.sol";
import {ICelerBridgeTokenV2} from "../interfaces/ICelerBridgeTokenV2.sol";

abstract contract AltInsureTokenBase is
    ERC20Upgradeable,
    OwnableUpgradeable,
    PolygonChildERC20Upgradeable,
    ICelerBridgeTokenV2
{
    struct Supply {
        uint256 cap;
        uint256 total;
    }

    mapping(address => Supply) public bridges;

    event SupplyCapChanged(address _bridge, uint256 _newCap);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __AltInsureBase_init(
        address _childChainManagerProxy
    ) public virtual initializer {
        __ERC20_init("AltInsureToken", "INSURE");
        __Ownable_init();
        __PolygonChildERC20_init(_childChainManagerProxy);
    }

    /**
     * external functions
     */

    function updateBridgeSupplyCap(
        address _bridge,
        uint256 _cap
    ) external onlyOwner {
        bridges[_bridge].cap = _cap;

        emit SupplyCapChanged(_bridge, _cap);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * public functions
     */

    function mint(
        address _to,
        uint256 _amount
    ) public virtual override(ICelerBridgeTokenV2) {
        Supply storage bridgeSupply = bridges[msg.sender];
        if (bridgeSupply.cap == 0) revert NotAllowedBridger();
        bridgeSupply.total += _amount;
        if (bridgeSupply.total > bridgeSupply.cap) revert ExceedSupplyCap();
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public virtual {
        _burn(_msgSender(), _amount);
    }

    function burn(
        address _from,
        uint256 _amount
    ) public virtual override(ICelerBridgeTokenV2) {
        _burnFrom(_from, _amount);
    }

    function burnFrom(
        address _from,
        uint256 _amount
    ) public virtual override(ICelerBridgeTokenV2) {
        _burnFrom(_from, _amount);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControlUpgradeable) returns (bool) {
        return
            AccessControlUpgradeable.supportsInterface(_interfaceId) ||
            _interfaceId == type(IPolygonChildERC20).interfaceId ||
            _interfaceId == type(ICelerBridgeTokenV1).interfaceId ||
            _interfaceId == type(ICelerBridgeTokenV2).interfaceId;
    }

    /**
     * internal functions
     */

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
}

error NotAllowedBridger();
error ExceedSupplyCap();
error BurnAmountExceeded();
