// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/ISofinaHub.sol";
import "../Project/Project.sol";
import "../Project/interfaces/IProject.sol";

contract SofinaHubV2 is ISofinaHub {
    /// @dev owner
    address private _owner;

    uint256 public numOfProjects;

    mapping(uint256 => address) public projects;

    /// @dev throws if called by any account other than the owner
    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "[SOFINAHUB]: Only SofinaHub can call this method."
        );
        _;
    }

    constructor() {
        _owner = msg.sender;
        numOfProjects = 0;
    }

    /// @dev returns the owner
    function owner() public view returns (address) {
        return _owner;
    }

    /// @dev
    /// Create a new Project contract
    /// [0] -> new Project contract address
    function create(SofinaHubOptions memory sofinaHub)
        public
        returns (IProject projectAddress)
    {
        // check project funding goal is greater than 0
        require(
            sofinaHub.fundingGoal > 0,
            "[SOFINAHUB]: Project funding goal must be greater than 0"
        );

        // check project deadline is greater than the current block
        require(
            block.number < sofinaHub.deadline,
            "[SOFINAHUB]: Project deadline must be greater than the current block"
        );

        IProject p = new Project(
            IProject.ProjectOptions(
                sofinaHub.fundingGoal,
                sofinaHub.deadline,
                sofinaHub.title,
                sofinaHub.description,
                payable(msg.sender),
                sofinaHub.images,
                sofinaHub.videos,
                sofinaHub.documents,
                sofinaHub.roi,
                sofinaHub.roiDuration,
                sofinaHub.tokenName,
                sofinaHub.tokenSymbol,
                sofinaHub.tokenDecimal,
                sofinaHub.tokenTotalSupply
            )
        );

        projects[numOfProjects] = address(p);

        emit LogProjectCreated(
            numOfProjects,
            sofinaHub.title,
            address(p),
            msg.sender
        );
        numOfProjects++;

        return p;
    }

    /// @dev
    /// Allow senders to contribute to a Project by it's address. Calls the fund() function in
    /// the Project contract and passes on all value attached to this function call
    /// [0] -> contribution was sent.
    function contribute(address payable _projectAddress)
        public
        payable
        returns (bool successful)
    {
        // check amount sent is greater than 0
        require(
            msg.value > 0,
            "[SOFINAHUB]: Contributions must be greater than 0 wei"
        );

        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // check that fund call was successful
        if (deployedProject.fund{value: msg.value}(payable(msg.sender))) {
            emit LogContributionSent(_projectAddress, msg.sender, msg.value);

            return true;
        } else {
            emit LogFailure(
                "[SOFINAHUB]: Contribution did not send successfully"
            );

            return false;
        }
    }

    /// @dev
    /// Allow contributor to withdraw their funds if funding cap not reached. Calls the refund()
    /// function in the Project contract and passes on all value attached to this function call.
    /// [0] -> contribution was sent.
    function refund(address payable _projectAddress)
        public
        payable
        returns (bool successful)
    {
        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // check that refund call was successful
        if (deployedProject.refund(payable(msg.sender))) {
            emit LogRefundSent(_projectAddress, msg.sender, msg.value);

            return true;
        } else {
            emit LogFailure("[SOFINAHUB]: Refund did not send successfully");

            return false;
        }
    }

    /// @dev
    function deposit(address payable _projectAddress)
        public
        payable
        returns (bool successful)
    {
        // check amount sent is greater than 0
        require(
            msg.value > 0,
            "[SOFINAHUB]: Project capital and ROI must be greater than 0 wei"
        );

        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // check that deposit call was successful
        if (deployedProject.deposit{value: msg.value}(payable(msg.sender))) {
            emit LogDepositSent(_projectAddress, msg.sender, msg.value);

            return true;
        } else {
            emit LogFailure(
                "[SOFINAHUB]: Project capital and ROI funds are not completed"
            );

            return false;
        }
    }

    function claim(address payable _projectAddress)
        public
        payable
        returns (bool successful)
    {
        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // check that claim call was successful
        if (deployedProject.claim(payable(msg.sender))) {
            emit LogClaimSent(_projectAddress, msg.sender, msg.value);

            return true;
        } else {
            emit LogFailure("[SOFINAHUB]: Claim did not send successfully");

            return false;
        }
    }

    /// @dev
    /// Verify property against scamming project
    function toggleVerify(address payable _projectAddress)
        public
        onlyOwner
        returns (bool successful)
    {
        Project deployedProject = Project(_projectAddress);

        // check that there is actually a project contract at that address
        require(deployedProject.sofinaHub() != address(0), "Project not exist");

        // toggle verification
        if (deployedProject.toggleVerify()) {
            emit LogToggleVerificationSent(
                "[SOFINAHUB]: Verification sent successfully"
            );

            return true;
        } else {
            emit LogFailure(
                "[SOFINAHUB]: Verification did not send successfully"
            );

            return false;
        }
    }
}
