// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IPolygonChildERC20} from "../interfaces/IPolygonChildERC20.sol";

abstract contract PolygonChildERC20Upgradeable is
    ERC20Upgradeable,
    AccessControlUpgradeable,
    IPolygonChildERC20
{
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    function __PolygonChildERC20_init(
        address _childChainManagerProxy
    ) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, _childChainManagerProxy);
    }

    /// @inheritdoc IPolygonChildERC20
    function deposit(
        address user,
        bytes calldata depositData
    ) external onlyRole(DEPOSITOR_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /// @inheritdoc IPolygonChildERC20
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}
