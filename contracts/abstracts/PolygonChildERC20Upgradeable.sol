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

    // This is to support Native meta transactions
    function _msgSender()
        internal
        view
        virtual
        override
        returns (address _sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                _sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            _sender = payable(msg.sender);
        }
        return _sender;
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
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
