// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error Crowdfunding_OnlyOwnerCanSendTransaction();
error Crowdfunding_CharityAlreadyRegistered();
error Crowdfunding_FundingAlreadyStarted();

contract Crowdfunding {
    enum FundingState {
        OPEN,
        CLOSED
    }

    address private immutable i_owner;
    FundingState private s_fundingState;
    uint256 private constant MINIMUM_USD = 1;
    address private s_winner;
    uint256 private s_winnerVotes;

    struct funder {
        bool voted;
        uint256 amountFunded;
    }
    mapping(address => funder) private s_funders;

    struct CharityOrganization {
        string name;
        address PublicAddress;
        uint256 votescount;
        bool registered;
    }
    CharityOrganization[] private s_charities;
    mapping(address => uint256) private s_charityIndex;

    constructor() {
        i_owner = msg.sender;
        s_fundingState = FundingState.CLOSED;
    }

    function addCharity(string memory _name, address _charityAddress) external {
        if (s_charities[s_charityIndex[_charityAddress]].registered) {
            revert Crowdfunding_CharityAlreadyRegistered();
        }
        s_charities.push(
            CharityOrganization({
                name: _name,
                PublicAddress: _charityAddress,
                votescount: 0,
                registered: true
            })
        );
        s_charityIndex[_charityAddress] = s_charities.length - 1;
    }

    function startFunding() public onlyOwner {
        if (s_fundingState == FundingState.OPEN) {
            revert Crowdfunding_FundingAlreadyStarted();
        }
        s_fundingState = FundingState.OPEN;
    }

    function fund(address _charityAddress) public payable {
        // Funder can vote only one time but he can fund money for unlimited time.
        funder memory currentFunder = s_funders[msg.sender];

        if (!currentFunder.voted) {
            s_charities[s_charityIndex[_charityAddress]].votescount++;
            currentFunder.voted = true;
        }
        currentFunder.amountFunded += msg.value;
        //uint256 ArrayIndex = s_AddToArrayIndex[_CharityIdentity];
    }

    function endFunding() public onlyOwner {
        s_fundingState = FundingState.CLOSED;
        address winner;
        uint256 HighestVotes = 0;
        for (uint256 i = 0; i < s_charities.length; i++) {
            if (s_charities[i].votescount > HighestVotes) {
                HighestVotes = s_charities[i].votescount;
                winner = s_charities[i].PublicAddress;
            }
        }
        s_winner = winner;
        s_winnerVotes = HighestVotes;
        transferFunds(winner);
    }

    function transferFunds(address _winner) internal {
        (bool Success, ) = payable(_winner).call{value: address(this).balance}("");
        require(Success, "Funds transfer failed :(");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Crowdfunding_OnlyOwnerCanSendTransaction();
        }
        _;
    }

    function getWinner() public view returns (address) {
        return s_winner;
    }

    function getWinnerVotes() public view returns (uint256) {
        return s_winnerVotes;
    }

    function getCharity(address _charityAddress) public view returns (CharityOrganization memory) {
        return s_charities[s_charityIndex[_charityAddress]];
    }
}
