// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {PolygonChildERC20Upgradeable} from "./PolygonChildERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ICelerBridgeToken} from "../interfaces/ICelerBridgeToken.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

abstract contract AltInsureTokenBase is
    ERC20Upgradeable,
    OwnableUpgradeable,
    PolygonChildERC20Upgradeable,
    ICelerBridgeToken
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
    ) public virtual override(ICelerBridgeToken) {
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
    ) public virtual override(ICelerBridgeToken) {
        _burnFrom(_from, _amount);
    }

    function burnFrom(
        address _from,
        uint256 _amount
    ) public virtual override(ICelerBridgeToken) {
        _burnFrom(_from, _amount);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public pure virtual override(AccessControlUpgradeable) returns (bool) {
        bytes4 thisFunctionInterface = bytes4(
            keccak256("supportsInterface(bytes4)")
        );

        bytes4 polygonStandardInterface = PolygonChildERC20Upgradeable
            .withdraw
            .selector ^ PolygonChildERC20Upgradeable.deposit.selector;

        bytes4 cBridgeInterfaceV1 = ICelerBridgeToken.mint.selector ^
            ICelerBridgeToken.burn.selector;

        bytes4 cBridgeInterfaceV2 = ICelerBridgeToken.mint.selector ^
            ICelerBridgeToken.burn.selector ^
            ICelerBridgeToken.burnFrom.selector;

        return
            _interfaceId == thisFunctionInterface ||
            _interfaceId == polygonStandardInterface ||
            _interfaceId == cBridgeInterfaceV1 ||
            _interfaceId == cBridgeInterfaceV2;
    }

    /**
     * internal functions
     */

    function _burnFrom(address _from, uint256 _amount) internal {
        Supply storage bridgeSupply = bridges[msg.sender];
        uint256 total = bridgeSupply.total;
        if (bridgeSupply.cap > 0 || total > 0) {
            if (total < _amount) revert BurnAmountExceeded();
            unchecked {
                bridgeSupply.total = total - _amount;
            }
        }
        _spendAllowance(_from, msg.sender, _amount);
        _burn(_from, _amount);
    }
}

error NotAllowedBridger();
error ExceedSupplyCap();
error BurnAmountExceeded();
