// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
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
    error NotAllowedBridger();
    error ExceedSupplyCap();
    error BurnAmountExceeded();

    struct Supply {
        uint256 cap;
        uint256 total;
    }

    mapping(address => Supply) public bridges;

    event BridgeSupplyChanged(
        address _bridge,
        uint256 _cap,
        bool _resetTotal,
        address _newBridge
    );

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

    function updateBridgeSupply(
        address _bridge,
        uint256 _cap,
        bool _resetTotal,
        address _newBridge
    ) external onlyOwner {
        // set cap to 1 and resetTotal: true would effectively disable a deprecated bridge's ability to burn
        // if the bridge is not considered malicious, set cap to 1 would be suffice to disable the bridge
        bridges[_bridge].cap = _cap;
        if (_resetTotal) {
            bridges[_newBridge].total += bridges[_bridge].total;
            bridges[_bridge].total = 0;
        }

        emit BridgeSupplyChanged(_bridge, _cap, _resetTotal, _newBridge);
    }

    /**
     * @notice Returns the owner address. Required by BEP20.
     */

    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * public functions
     */

    /**
     * @notice This function overrides ERC20#transferFrom function to prevent a malicious bridger to transfer user's token
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        // bridger cannot call this function
        if (bridges[spender].cap > 0) revert NotAllowedBridger();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

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
        _burn(msg.sender, _amount);
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

    /// @inheritdoc PolygonChildERC20Upgradeable
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, PolygonChildERC20Upgradeable)
        returns (address _sender)
    {
        return PolygonChildERC20Upgradeable._msgSender();
    }

    function _burnFrom(address _from, uint256 _amount) internal {
        Supply storage bridgeSupply = bridges[msg.sender];
        // set cap to 1 would effectively disable a deprecated bridge's ability to burn
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
