// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IProject {
    struct ProjectOptions {
        uint256 _fundingGoal;
        uint256 _deadline;
        string _title;
        string _description;
        address payable _creator;
        string[] _images;
        string[] _videos;
        string[] _documents;
        uint256 _roi;
        uint256 _roiDuration;
        string _tokenName;
        string _tokenSymbol;
        uint8 _tokenDecimal;
        uint256 _tokenTotalSupply;
    }

    struct Properties {
        uint256 goal;
        uint256 deadline;
        string title;
        string description;
        address payable creator;
        string[] images;
        string[] videos;
        string[] documents;
        uint256 roi;
        uint256 roiDuration;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimal;
        uint256 tokenTotalSupply;
        address tokenAddress;
        bool verified;
    }

    struct Contribution {
        uint256 amount;
        address contributor;
    }

    event LogContributionReceived(
        address projectAddress,
        address contributor,
        uint256 amount
    );

    event LogPayoutInitiated(
        address projectAddress,
        address owner,
        uint256 totalPayout
    );

    event LogRefundIssued(
        address projectAddress,
        address contributor,
        uint256 refundAmount
    );

    event LogFundingGoalReached(
        address projectAddress,
        uint256 totalFunding,
        uint256 totalContributions
    );

    event LogFundingFailed(
        address projectAddress,
        uint256 totalFunding,
        uint256 totalContributions
    );

    event LogDeposited(string message, uint256 amount);

    event LogClaimSent(
        address projectAddress,
        address contributor,
        uint256 refundAmount
    );

    event LogFailure(string message);

    /// @dev
    function getProject()
        external
        view
        returns (
            Properties memory,
            uint256,
            uint256,
            uint256,
            address,
            address
        );

    /// @dev
    function getContribution(uint256 _id)
        external
        view
        returns (uint256, address);

    /// @dev
    function fund(address payable _contributor)
        external
        payable
        returns (bool successful);

    /// @dev
    function payout() external payable returns (bool successful);

    /// @dev
    function refund(address payable _contributor)
        external
        payable
        returns (bool successful);

    /// @dev
    function deposit(address payable _creator)
        external
        payable
        returns (bool successful);

    /// @dev
    function claim(address payable _contributor)
        external
        payable
        returns (bool successful);

    /// @dev
    function toggleVerify() external returns (bool successful);

    /// @dev
    receive() external payable;
}
