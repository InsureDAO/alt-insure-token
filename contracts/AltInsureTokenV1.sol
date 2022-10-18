// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {PolygonChildERC20Upgradeable} from "./abstracts/PolygonChildERC20Upgradeable.sol";
import {OptimismERC20Upgradeable} from "./abstracts/OptimismERC20Upgradeable.sol";
import {ArbitrumERC20Upgradeable} from "./abstracts/ArbitrumERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ICelerBridgeToken} from "./interfaces/ICelerBridgeToken.sol";
import {IArbToken} from "./interfaces/IArbToken.sol";
import "hardhat/console.sol";

import "./interfaces/IOptimismStandardERC20.sol";

contract AltInsureTokenV1 is
    ERC20Upgradeable,
    OwnableUpgradeable,
    OptimismERC20Upgradeable,
    ArbitrumERC20Upgradeable,
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

    function initialize(
        address _l1Token,
        address _childChainManagerProxy,
        address _l2Gateway
    ) public virtual initializer {
        __ERC20_init("InsureToken", "INSURE");
        __Ownable_init();
        __PolygonChildERC20_init(_childChainManagerProxy);
        __OptimismERC20_init(_l1Token);
        __ArbitrumERC20_init(_l2Gateway, _l1Token);
    }

    function mint(address _to, uint256 _amount)
        external
        override(OptimismERC20Upgradeable, ICelerBridgeToken)
    {
        Supply storage bridgeSupply = bridges[msg.sender];
        if (bridgeSupply.cap == 0) revert NotAllowedBridger();
        bridgeSupply.total += _amount;
        if (bridgeSupply.total > bridgeSupply.cap) revert ExceedSupplyCap();
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
    }

    function burn(address _from, uint256 _amount)
        external
        override(OptimismERC20Upgradeable, ICelerBridgeToken)
    {
        _burnFrom(_from, _amount);
    }

    function burnFrom(address _from, uint256 _amount) external {
        _burnFrom(_from, _amount);
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

        emit SupplyCapChanged(_bridge, _cap);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        pure
        override(AccessControlUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        bytes4 thisFunctionInterface = bytes4(
            keccak256("supportsInterface(bytes4)")
        );

        bytes4 optimismStandardInterface = IOptimismStandardERC20
            .l1Token
            .selector ^
            IOptimismStandardERC20.mint.selector ^
            IOptimismStandardERC20.burn.selector;

        bytes4 arbitrumStandardInterface = IArbToken.l1Address.selector ^
            IArbToken.bridgeMint.selector ^
            IArbToken.bridgeBurn.selector;

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
            _interfaceId == optimismStandardInterface ||
            _interfaceId == arbitrumStandardInterface ||
            _interfaceId == polygonStandardInterface ||
            _interfaceId == cBridgeInterfaceV1 ||
            _interfaceId == cBridgeInterfaceV2;
    }
}

error NotAllowedBridger();
error ExceedSupplyCap();
error BurnAmountExceeded();
