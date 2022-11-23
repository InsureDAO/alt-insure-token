// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IOptimismStandardERC20} from "../interfaces/IOptimismStandardERC20.sol";
import {AddressZero} from "../errors/CommonErrors.sol";

abstract contract OptimismERC20Upgradeable is
    Initializable,
    IOptimismStandardERC20
{
    address public l1Token;

    function __OptimismERC20_init(address _l1Token) internal onlyInitializing {
        if (_l1Token == address(0)) revert AddressZero();
        l1Token = _l1Token;
    }

    function mint(address _to, uint256 _amount) external virtual;

    function burn(address _from, uint256 _amount) external virtual;
}
