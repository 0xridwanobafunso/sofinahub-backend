// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC20 {
    /// @dev Tranfer and Approval events

    /// @dev Emitted when `value` tokens are moved from one account (`from`) to
    /// @dev another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set by
    /// @dev a call to {approve}. `value` is the new allowance.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @dev get the name of the token
    function name() external view returns (string memory);

    /// @dev get the symbol of the token
    function symbol() external view returns (string memory);

    /// @dev get the decimals of the token
    function decimals() external view returns (uint8);

    /// @dev get the total tokens in supply
    function totalSupply() external view returns (uint256);

    /// @dev get balance of an account
    function balanceOf(address account) external view returns (uint256);

    /// @dev approve address/contract to spend a specific amount of token
    function approve(address spender, uint256 amount) external returns (bool);

    /// @dev get the remaining amount approved for address/contract
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @dev send token from current address/contract to another recipient
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @dev automate sending of token from approved sender address/contract to another
    /// @dev recipient
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev
    ///
    function sendReward(address contributor, uint256 amount)
        external
        returns (bool);
}
