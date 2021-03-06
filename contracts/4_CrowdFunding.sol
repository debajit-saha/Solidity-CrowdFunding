// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

contract CrowdFunding {
    // Models for Fund, Investement
    struct Fund {
        uint256 id;
        string name;
        string description;
        uint256 startDate;
        uint256 endDate;
        uint256 goalAmount;
        uint256 currentAmount;
        bool isActive;
        address payable receiverAddress;
    }
    struct Investment {
        uint256 id;
        uint256 fundId;
        address investorAddress;
        uint256 investorAmount;
        uint256 investmentDate;
    }

    address public manager;
    mapping(uint256 => Fund) funds;
    Investment[] investments;
    uint256 fundCount;
    uint256 investmentCount;

    // Set manager/owner of this contract.
    constructor() {
        manager = msg.sender;
    }

    // Modifier which checks sender is manager.
    modifier onlyBy(address account) {
        require(account == msg.sender, "Sender not authorized.");
        _;
    }

    event FundCreated(Fund fund);
    event FundUpdated(Fund fund);
    event InvestmentCreated(Investment investment);
    event AmountPaid(Fund fund);

    function changeManager(address newManager) public onlyBy(manager) {
        manager = newManager;
    }

    // Create a new fund. Only manager is allowed to create it.
    function createFund(
        string memory name,
        string memory description,
        uint256 startDate,
        uint256 endDate,
        uint256 goalAmount,
        address payable receiverAddress
    ) public onlyBy(manager) {
        require(
            startDate > block.timestamp,
            "Start date-time should be greater than current date-time."
        );
        require(
            endDate > startDate,
            "End date-time should be greater than start date-time."
        );

        Fund storage newFund = funds[fundCount];
        newFund.id = fundCount;
        newFund.name = name;
        newFund.description = description;
        newFund.startDate = startDate;
        newFund.endDate = endDate;
        newFund.goalAmount = goalAmount;
        newFund.currentAmount = 0;
        newFund.receiverAddress = receiverAddress;
        newFund.isActive = true;
        fundCount++;

        emit FundCreated(newFund);
    }

    // Get all funds.
    function getAllFunds() public view returns (Fund[] memory) {
        Fund[] memory fundList = new Fund[](fundCount);

        for (uint256 i = 0; i < fundCount; i++) {
            fundList[i] = funds[i];
        }

        return fundList;
    }

    // Get a fund by Id.
    function getFundById(uint256 fundId) public view returns (Fund memory) {
        return funds[fundId];
    }

    // Create a new investment.
    function createInvestment(uint256 fundId) public payable {
        Fund storage fund = funds[fundId];
        require(fund.isActive, "Fund is closed.");
        require(fund.startDate <= block.timestamp, "Fund has not started yet.");

        investments.push(
            Investment(
                investmentCount,
                fundId,
                msg.sender,
                msg.value,
                block.timestamp
            )
        );
        investmentCount++;
        fund.currentAmount += msg.value;

        emit InvestmentCreated(investments[investmentCount - 1]);
        emit FundUpdated(fund);
    }

    // Get all investements for a fund.
    function getAllInvestmentsForFund(uint256 fundId)
        public
        view
        returns (Investment[] memory)
    {
        Investment[] memory investmentList = new Investment[](investmentCount);
        uint256 count = 0;

        for (uint256 i = 0; i < investmentCount; i++) {
            if (investments[i].fundId == fundId) {
                investmentList[count] = investments[i];
                count++;
            }
        }

        return investmentList;
    }

    // Transfer amount to fund recipient.
    function makePayment(uint256 fundId) public onlyBy(manager) {
        Fund storage fund = funds[fundId];
        require(fund.isActive, "Fund is closed.");
        require(
            fund.currentAmount >= fund.goalAmount ||
                fund.endDate < block.timestamp,
            "Fund is active, cannot transfer amount now."
        );

        fund.receiverAddress.transfer(fund.currentAmount);
        fund.isActive = false;

        emit AmountPaid(fund);
    }
}
