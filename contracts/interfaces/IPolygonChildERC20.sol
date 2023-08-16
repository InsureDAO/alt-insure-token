// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPolygonChildERC20 {
    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param _user user address for whom deposit is being done
     * @param _depositData abi encoded amount
     */
    function deposit(address _user, bytes calldata _depositData) external;

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param _amount amount of tokens to withdraw
     */
    function withdraw(uint256 _amount) external;
}
