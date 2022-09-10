// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IERC20.sol";

contract Token is IERC20 {
    /// @dev name of the token
    string public name;

    /// @dev symbol of the token
    string public symbol;

    /// @dev decimal place the amount of the token will be calculated
    uint8 public decimals;

    /// @dev total supply
    uint256 public totalSupply;

    /// @dev owner of the token
    address public owner;

    /// @dev create a table so that we can map addresses to the balances associated with them
    mapping(address => uint256) balances;

    /// @dev create a table so that we can map the addresses of contract owners to those
    /// @dev who are allowed to utilize the owner's contract
    mapping(address => mapping(address => uint256)) allowed;

    /// @dev throws if called by any account other than the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev run during the deployment of smart contract
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address _owner
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * (10**_decimals);
        owner = _owner;

        balances[owner] = totalSupply;
    }

    /// @dev get balance of an account
    function balanceOf(address account) public view override returns (uint256) {
        // return the balance for the specific address
        return balances[account];
    }

    /// @dev approve address/contract to spend a specific amount of token
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        allowed[msg.sender][spender] = amount;

        // fire the event "Approval" to execute any logic
        // that was listening to it
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /// @dev get the remaining amount approved for address/contract
    function allowance(address _owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][spender];
    }

    /// @dev send token from current address/contract to another recipient
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        // if the sender has sufficient funds to send
        // and the amount is not zero, then send to
        // the given address
        if (
            balances[msg.sender] >= amount &&
            amount > 0 &&
            balances[recipient] + amount > balances[recipient]
        ) {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;

            // fire a transfer event for any logic that's listening
            emit Transfer(msg.sender, recipient, amount);

            return true;
        } else {
            return false;
        }
    }

    /// @dev automate sending of token from approved sender address/contract to another
    /// @dev recipient
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (
            balances[sender] >= amount &&
            allowed[sender][msg.sender] >= amount &&
            amount > 0 &&
            balances[recipient] + amount > balances[recipient]
        ) {
            balances[sender] -= amount;
            balances[recipient] += amount;

            // fire a transfer event for any logic that's listening
            emit Transfer(sender, recipient, amount);

            return true;
        } else {
            return false;
        }
    }

    /// @dev
    ///
    function sendReward(address contributor, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        transfer(contributor, amount);

        return true;
    }
}
