// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IProject.sol";
import "../Token/Token.sol";
import "../Token/interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";

contract Project is IProject {
    using SafeMath for uint256;

    address public sofinaHub;
    address public projectToken;

    mapping(address => uint256) public contributors;
    mapping(uint256 => Contribution) public contributions;

    uint256 public totalFunding;
    uint256 public contributionsCount;
    uint256 public contributorsCount;

    Properties public properties;

    ///
    modifier onlySofinaHub() {
        require(
            sofinaHub == msg.sender,
            "[SOFINAHUB]: Only SofinaHub can call this method."
        );
        _;
    }

    ///
    modifier onlyFundCapReached() {
        require(
            totalFunding >= properties.goal,
            "[SOFINAHUB_PROJECT]: Fund withdrawal is currently not available."
        );
        _;
    }

    ///
    constructor(ProjectOptions memory project) {
        // check to see the funding goal is greater than 0
        require(
            project._fundingGoal > 0,
            "[SOFINAHUB_PROJECT]: Project funding goal must be greater than 0 wei"
        );

        // check to see the deadline is in the future
        require(
            block.number < project._deadline,
            "[SOFINAHUB_PROJECT]: Project deadline must be greater than the current block"
        );

        // Check to see that a creator (payout) address is valid
        require(
            project._creator != address(0),
            "[SOFINAHUB_PROJECT]: Project must include a valid creator address e.g burner address not allowed"
        );

        sofinaHub = msg.sender;

        // create project token
        IERC20 projectTokenAddress = new Token(
            project._tokenName,
            project._tokenSymbol,
            project._tokenDecimal,
            project._tokenTotalSupply,
            address(this)
        );

        // initialize properties struct
        properties = Properties(
            project._fundingGoal,
            project._deadline,
            project._title,
            project._description,
            project._creator,
            project._images,
            project._videos,
            project._documents,
            project._roi,
            project._roiDuration,
            project._tokenName,
            project._tokenSymbol,
            project._tokenDecimal,
            project._tokenTotalSupply,
            address(projectTokenAddress),
            false
        );

        totalFunding = 0;
        contributionsCount = 0;
        contributorsCount = 0;
    }

    /// @dev
    /// Project values are indexed in return value:
    /// [0] -> Project.properties
    /// [1] -> Project.totalFunding
    /// [2] -> Project.contributionsCount
    /// [3] -> Project.contributorsCount
    /// [4] -> Project.sofinaHub
    /// [5] -> Project (address)
    function getProject()
        public
        view
        returns (
            Properties memory,
            uint256,
            uint256,
            uint256,
            address,
            address
        )
    {
        return (
            properties,
            totalFunding,
            contributionsCount,
            contributorsCount,
            sofinaHub,
            address(this)
        );
    }

    /// @dev
    /// Retrieve indiviual contribution information
    /// Contribution.amount
    /// Contribution.contributor
    function getContribution(uint256 _id)
        public
        view
        returns (uint256, address)
    {
        Contribution memory c = contributions[_id];
        return (c.amount, c.contributor);
    }

    /// @dev
    /// This is the function called when the sofinaHub receives a contribution.
    /// If the contribution was sent after the deadline of the project passed,
    /// or the full amount has been reached, the function must return the value
    /// to the originator of the transaction.
    /// If the full funding amount has been reached, the function must call payout.
    /// [0] -> contribution was made
    function fund(address payable _contributor)
        public
        payable
        onlySofinaHub
        returns (bool successful)
    {
        // check amount is greater than 0
        require(
            msg.value > 0,
            "[SOFINAHUB_PROJECT]: Funding contributions must be greater than 0 wei"
        );

        // check that the project dealine has not passed
        if (block.number > properties.deadline) {
            emit LogFundingFailed(
                address(this),
                totalFunding,
                contributionsCount
            );

            require(
                _contributor.send(msg.value),
                "[SOFINAHUB_PROJECT]: Project deadline has passed, problem returning contribution"
            );

            return false;
        }

        // check that funding goal has not already been met
        if (totalFunding >= properties.goal) {
            emit LogFundingGoalReached(
                address(this),
                totalFunding,
                contributionsCount
            );

            require(
                _contributor.send(msg.value),
                "[SOFINAHUB_PROJECT]: Project deadline has passed, problem returning contribution"
            );

            return false;
        }

        // determine if this is a new contributor
        uint256 prevContributionBalance = contributors[_contributor];

        // Add contribution to contributions map
        Contribution storage c = contributions[contributionsCount];
        c.contributor = _contributor;
        c.amount = msg.value;

        // Update contributor's balance
        contributors[_contributor] += msg.value;

        totalFunding += msg.value;
        contributionsCount++;

        // Check if contributor is new and if so increase count
        if (prevContributionBalance == 0) {
            contributorsCount++;
        }

        emit LogContributionReceived(address(this), _contributor, msg.value);

        // send token to contributor
        IERC20 token = Token(properties.tokenAddress);

        // send reward to contributor
        token.sendReward(
            _contributor,
            (msg.value /
                (
                    properties.goal.div(
                        properties.tokenTotalSupply *
                            10**properties.tokenDecimal
                    )
                ))
        );

        // Check again to see whether the last contribution met the fundingGoal
        if (totalFunding >= properties.goal) {
            emit LogFundingGoalReached(
                address(this),
                totalFunding,
                contributionsCount
            );

            payout();
        }

        return true;
    }

    /// @dev
    /// If funding goal has been met, transfer fund to project creator
    /// [0] -> payout was successful
    function payout()
        public
        payable
        onlyFundCapReached
        returns (bool successful)
    {
        uint256 amount = totalFunding;

        if (properties.creator.send(amount)) {
            return true;
        } else {
            totalFunding = amount;

            return false;
        }
    }

    /// @dev
    /// If the deadline is passed and the goal was not reached, allow contributors to withdraw
    /// their contributions.
    /// [0] -> refund was successful
    function refund(address payable _contributor)
        public
        payable
        onlySofinaHub
        returns (bool successful)
    {
        // check that the project dealine has passed
        require(
            block.number > properties.deadline,
            "[SOFINAHUB_PROJECT]: Refund is only possible if project is past deadline"
        );

        // check that funding goal has not already been met
        require(
            totalFunding < properties.goal,
            "[SOFINAHUB_PROJECT]: Refund is not possible if project has met goal"
        );

        // token
        IERC20 token = Token(properties.tokenAddress);

        // contributor token balance
        uint256 balance = token.balanceOf(_contributor);

        // check if the contributor token balance is greater than zero
        require(
            balance > 0,
            "[SOFINAHUB_PROJECT]: Contributor token balance must be greater than zero"
        );

        uint256 amount = contributors[_contributor];

        // prevent re-entrancy attack
        contributors[_contributor] = 0;

        // transfer the rewarded token to this project
        token.transferFrom(_contributor, address(this), balance);

        if (payable(_contributor).send(amount)) {
            emit LogRefundIssued(address(this), _contributor, amount);

            return true;
        } else {
            contributors[_contributor] = amount;

            emit LogFailure(
                "[SOFINAHUB_PROJECT]: Refund did not send successfully"
            );
            return false;
        }
    }

    /// @dev
    function deposit(address payable _creator)
        public
        payable
        onlySofinaHub
        returns (bool successful)
    {
        require(
            properties.creator == _creator,
            "[SOFINAHUB_PROJECT]: You're not the creator of this project"
        );

        require(
            block.number >= properties.roiDuration,
            "[SOFINAHUB_PROJECT]: Project ROI duration hasn't been reached to start disbursement"
        );

        uint256 expectedFunds = properties
            .roi
            .div(100)
            .mul(properties.goal)
            .add(properties.goal);

        if (msg.value < expectedFunds) {
            // return funds to creator
            require(
                _creator.send(msg.value),
                "[SOFINAHUB_PROJECT]: Problem returning creator fund"
            );

            return false;
        }

        emit LogDeposited(
            "[SOFINAHUB_PROJECT]: Project capital and ROI funds deposited successfully",
            expectedFunds
        );

        return true;
    }

    /// @dev
    function claim(address payable _contributor)
        public
        payable
        onlySofinaHub
        returns (bool successful)
    {
        // token
        IERC20 token = Token(properties.tokenAddress);

        // contributor token balance
        uint256 balance = token.balanceOf(_contributor);

        // check if the contributor token balance is greater than zero
        require(
            balance > 0,
            "[SOFINAHUB_PROJECT]: Contributor token balance must be greater than zero"
        );

        // capital and roi
        uint256 capital = properties
            .goal
            .div(properties.tokenTotalSupply * 10**properties.tokenDecimal)
            .mul(balance);

        // [properties.roi.div(100).mul(capital)] = 0
        uint256 roi = capital.mul(properties.roi).div(100);

        // transfer the rewarded token to this project
        token.transferFrom(_contributor, address(this), balance);

        if (payable(_contributor).send(capital.add(roi))) {
            emit LogClaimSent(address(this), _contributor, capital.add(roi));

            return true;
        } else {
            emit LogFailure(
                "[SOFINAHUB_PROJECT]: Claim did not send successfully"
            );
            return false;
        }
    }

    /// @dev
    function toggleVerify() public onlySofinaHub returns (bool successful) {
        properties.verified = !properties.verified;

        return true;
    }

    /// @dev Don't allow Ether to be sent blindly to this contract
    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
