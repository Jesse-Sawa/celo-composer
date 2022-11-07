// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hackathon {
    uint32 constant minimumVotingPeriod = 1 weeks;
    uint256 numOfProposals;
    address[] eligibleVotersArray;

    enum State {
        Invalid,
        Created,
        Voted,
        Delegated
    }

    struct Proposal {
        uint256 id;
        uint256 amount;
        uint256 livePeriod;
        uint256 votesFor;
        uint256 votesAgainst;
        string description;
        bool votingPassed;
        address proposer;
    }

    struct Voter {
        address voterAddress;
        uint[] votes; // mapping proposal indexed voted for
        uint index; // index of the this voter in eligibleVoters[] //todo
        State state;
    }

    mapping(uint256 => Proposal) private carbonEmissionProposals;
    mapping(address => uint256[]) private historicalVotes;
    mapping(address => Voter) public eligibleVoters;

    event NewCarbonEmissionsProposal(
        address indexed proposer,
        string description,
        uint256 proposalId
    );

    // todo can make this onlyOwner for now
    function addVoter(address voterAddress) public {
        uint[] memory emptyDelegation = new uint[](0);
        eligibleVoters[voterAddress] = Voter(
            msg.sender,
            emptyDelegation,
            eligibleVotersArray.length,
            State.Created
        );
        eligibleVotersArray.push(voterAddress);
    }

    function createProposal(string calldata description) external {
        uint256 proposalId = numOfProposals++;
        Proposal storage proposal = carbonEmissionProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.livePeriod = block.timestamp + minimumVotingPeriod;

        emit NewCarbonEmissionsProposal(msg.sender, description, proposalId);
    }

    function vote(uint256 proposalId, bool supportProposal) external {
        Proposal storage proposal = carbonEmissionProposals[proposalId];

        votable(proposal);

        if (supportProposal) proposal.votesFor++;
        else proposal.votesAgainst++;

        historicalVotes[msg.sender].push(proposal.id);
    }

    function votable(Proposal storage carbonEmissionsProposal) private {
        if (
            carbonEmissionsProposal.votingPassed ||
            carbonEmissionsProposal.livePeriod <= block.timestamp
        ) {
            carbonEmissionsProposal.votingPassed = true;
            revert("Voting period has passed on this proposal");
        }

        uint256[] memory tempVotes = historicalVotes[msg.sender];
        for (uint256 votes = 0; votes < tempVotes.length; votes++) {
            if (carbonEmissionsProposal.id == tempVotes[votes])
                revert("This stakeholder already voted on this proposal");
        }
    }

    // TODO look into payable property
    //    receive() external payable {
    //        emit ContributionReceived(msg.sender, msg.value);
    //    }

    function getProposals() public view returns (Proposal[] memory props) {
        props = new Proposal[](numOfProposals);

        for (uint256 index = 0; index < numOfProposals; index++) {
            props[index] = carbonEmissionProposals[index];
        }
    }

    function getProposal(
        uint256 proposalId
    ) public view returns (Proposal memory) {
        return carbonEmissionProposals[proposalId];
    }

    function getHistoricalVotes() public view returns (uint256[] memory) {
        return historicalVotes[msg.sender];
    }

    function isVoter() public view returns (bool) {
        // TODO Confirm this returns if stakeholder was added
        return eligibleVoters[msg.sender].state != State.Invalid;
    }
}
