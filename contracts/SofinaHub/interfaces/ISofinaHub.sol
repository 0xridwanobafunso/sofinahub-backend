// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../../Project/interfaces/IProject.sol";

interface ISofinaHub {
    struct SofinaHubOptions {
        uint256 fundingGoal;
        uint256 deadline;
        string title;
        string description;
        string[] images;
        string[] videos;
        string[] documents;
        uint256 roi;
        uint256 roiDuration;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimal;
        uint256 tokenTotalSupply;
    }

    event LogProjectCreated(
        uint256 id,
        string title,
        address addr,
        address creator
    );

    event LogContributionSent(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogDepositSent(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogRefundSent(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogClaimSent(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogToggleVerificationSent(string message);

    event LogFailure(string message);

    /// @dev
    function create(SofinaHubOptions memory sofinaHub)
        external
        returns (IProject projectAddress);

    /// @dev
    function contribute(address payable _projectAddress)
        external
        payable
        returns (bool successful);

    /// @dev
    function refund(address payable _projectAddress)
        external
        payable
        returns (bool successful);

    /// @dev
    function deposit(address payable _projectAddress)
        external
        payable
        returns (bool successful);

    /// @dev
    function claim(address payable _projectAddress)
        external
        payable
        returns (bool successful);

    /// @dev
    function toggleVerify(address payable _projectAddress)
        external
        returns (bool successful);
}
