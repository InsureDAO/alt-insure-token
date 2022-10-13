// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// import {IL2StandardERC20} from "@eth-optimism/contracts/standards/IL2StandardERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IOptimismStandardERC20.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

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

// abstract contract OptimismERC20Upgradable is
//     IL2StandardERC20,
//     ERC20Upgradeable
// {
//     address public l1Token;

//     function __OptimismERC20_init(address _l1Token) internal initializer {
//         l1Token = _l1Token;
//     }

//     function mint(address _to, uint256 _amount) external virtual;

//     function burn(address _from, uint256 _amount) external virtual;

//     function supportsInterface(bytes4 _interfaceId)
//         external
//         view
//         virtual
//         returns (bool)
//     {
//         bytes4 firstSupportedInterface = bytes4(
//             keccak256("supportsInterface(bytes4)")
//         );
//         bytes4 secondSupportedInterface = IL2StandardERC20.l1Token.selector ^
//             IL2StandardERC20.mint.selector ^
//             IL2StandardERC20.burn.selector;

//         return
//             _interfaceId == firstSupportedInterface ||
//             _interfaceId == secondSupportedInterface;
//     }

//     function allowance(address _owner, address _spender)
//         public
//         view
//         virtual
//         override(IERC20, ERC20Upgradeable)
//         returns (uint256)
//     {
//         return super.allowance(_owner, _spender);
//     }

//     function approve(address _spender, uint256 _amount)
//         public
//         virtual
//         override(IERC20, ERC20Upgradeable)
//         returns (bool)
//     {
//         return super.approve(_spender, _amount);
//     }

//     function balanceOf(address _account)
//         public
//         view
//         virtual
//         override(IERC20, ERC20Upgradeable)
//         returns (uint256)
//     {
//         return super.balanceOf(_account);
//     }

//     function totalSupply()
//         public
//         view
//         virtual
//         override(IERC20, ERC20Upgradeable)
//         returns (uint256)
//     {
//         return super.totalSupply();
//     }

//     function transfer(address _to, uint256 _amount)
//         public
//         virtual
//         override(IERC20, ERC20Upgradeable)
//         returns (bool)
//     {
//         return super.transfer(_to, _amount);
//     }

//     function transferFrom(
//         address _from,
//         address _to,
//         uint256 _amount
//     ) public virtual override(IERC20, ERC20Upgradeable) returns (bool) {
//         return super.transferFrom(_from, _to, _amount);
//     }
// }
