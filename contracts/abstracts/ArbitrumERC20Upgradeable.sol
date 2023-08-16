// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IArbToken} from "../interfaces/IArbToken.sol";
import {AddressZero} from "../errors/CommonErrors.sol";

abstract contract ArbitrumERC20Upgradeable is
    Initializable,
    ERC20Upgradeable,
    IArbToken
{
    address public l2Gateway;
    /// @inheritdoc IArbToken
    address public l1Address;

    modifier onlyGateway() {
        if (msg.sender != l2Gateway) revert OnlyArbGateway();
        _;
    }

    function __ArbitrumERC20_init(
        address _l2Gateway,
        address _l1Address
    ) internal onlyInitializing {
        if (_l1Address == address(0)) revert AddressZero();
        l2Gateway = _l2Gateway;
        l1Address = _l1Address;
    }

    /**
     * @inheritdoc IArbToken
     */
    function bridgeMint(address _to, uint256 _amount) external onlyGateway {
        _mint(_to, _amount);
    }

    /**
     * @inheritdoc IArbToken
     */
    function bridgeBurn(address _from, uint256 _amount) external onlyGateway {
        _burn(_from, _amount);
    }
}

error OnlyArbGateway();
