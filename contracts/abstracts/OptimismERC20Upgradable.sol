// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IOptimismStandardERC20} from "../interfaces/IOptimismStandardERC20.sol";

abstract contract OptimismERC20Upgradable is
    Initializable,
    IOptimismStandardERC20
{
    address public l1Token;

    function __OptimismERC20_init(address _l1Token) internal onlyInitializing {
        l1Token = _l1Token;
    }

    function mint(address _to, uint256 _amount) external virtual;

    function burn(address _from, uint256 _amount) external virtual;

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        bytes4 firstSupportedInterface = bytes4(
            keccak256("supportsInterface(bytes4)")
        );
        bytes4 secondSupportedInterface = IOptimismStandardERC20
            .l1Token
            .selector ^
            IOptimismStandardERC20.mint.selector ^
            IOptimismStandardERC20.burn.selector;

        return
            _interfaceId == firstSupportedInterface ||
            _interfaceId == secondSupportedInterface;
    }
}
