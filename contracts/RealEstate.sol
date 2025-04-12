// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Real Estate Smart Contract - Track Property Details and Renting with Deposits and Late Fees
contract RealEstate {
    uint256 public propertyCount = 0;

    enum Status {
        Available,
        Rented
    }

    struct Property {
        uint256 id;
        string name;
        string location;
        address payable owner;
        address renter;
        uint256 rentPrice;
        uint256 deposit;
        uint256 lastPaid;
        Status status;
    }

    mapping(uint256 => Property) public properties;

    // --- MODIFIERS ---
    modifier onlyOwner(uint256 _propertyId) {
        require(
            msg.sender == properties[_propertyId].owner,
            "Not property owner"
        );
        _;
    }

    modifier onlyRenter(uint256 _propertyId) {
        require(
            msg.sender == properties[_propertyId].renter,
            "Not renter of this property"
        );
        _;
    }

    modifier onlyWhenRented(uint256 _propertyId) {
        require(
            properties[_propertyId].status == Status.Rented,
            "Property is not rented"
        );
        _;
    }

    modifier onlyWhenAvailable(uint256 _propertyId) {
        require(
            properties[_propertyId].status == Status.Available,
            "Property is not available"
        );
        _;
    }

    modifier renterHasPaid(uint256 _propertyId) {
        Property storage prop = properties[_propertyId];
        require(prop.lastPaid > 0, "Renter has not paid yet");
        _;
    }

    // --- FUNCTIONS ---
    function addProperty(
        string memory _name,
        string memory _location,
        uint256 _rentPrice,
        uint256 _deposit
    ) public {
        propertyCount++;
        properties[propertyCount] = Property({
            id: propertyCount,
            name: _name,
            location: _location,
            owner: payable(msg.sender),
            renter: address(0),
            rentPrice: _rentPrice,
            deposit: _deposit,
            lastPaid: 0,
            status: Status.Available
        });
    }

    function rentProperty(uint256 _propertyId)
        public
        payable
        onlyWhenAvailable(_propertyId)
    {
        Property storage prop = properties[_propertyId];
        require(
            msg.sender != prop.owner,
            "Owner cannot rent their own property"
        );
        require(
            msg.value >= prop.rentPrice + prop.deposit,
            "Insufficient rent payment + deposit"
        );

        prop.renter = msg.sender;
        prop.status = Status.Rented;
        prop.lastPaid = block.timestamp;

        // Transfer rent and deposit to owner
        prop.owner.transfer(prop.rentPrice);
        prop.owner.transfer(prop.deposit);
    }

    function endRental(uint256 _propertyId) public onlyWhenRented(_propertyId) {
        Property storage prop = properties[_propertyId];
        require(
            msg.sender == prop.owner || msg.sender == prop.renter,
            "Only owner or renter can end rental"
        );

        if (msg.sender == prop.owner) {
            // If owner ends rental, return deposit to renter
            payable(prop.renter).transfer(prop.deposit);
        }

        prop.renter = address(0);
        prop.status = Status.Available;
        prop.lastPaid = 0;
    }

    function payRent(uint256 _propertyId)
        public
        payable
        onlyRenter(_propertyId)
        onlyWhenRented(_propertyId)
        renterHasPaid(_propertyId)
    {
        Property storage prop = properties[_propertyId];
        uint256 currentTime = block.timestamp;

        uint256 totalAmount = prop.rentPrice;
        require(
            msg.value >= totalAmount,
            "Insufficient payment including late fee"
        );

        // Transfer rent and late fee to the owner
        prop.owner.transfer(prop.rentPrice);

        prop.lastPaid = currentTime;
    }

    function getProperty(uint256 _propertyId)
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            address,
            address,
            uint256,
            uint256,
            Status
        )
    {
        Property memory prop = properties[_propertyId];
        return (
            prop.id,
            prop.name,
            prop.location,
            prop.owner,
            prop.renter,
            prop.rentPrice,
            prop.deposit,
            prop.status
        );
    }

    // --- OWNER FUNCTIONS ---

    /// @notice Chủ sở hữu cập nhật giá thuê
    function updateRentPrice(uint256 _propertyId, uint256 _newRentPrice)
        public
        onlyOwner(_propertyId)
    {
        Property storage prop = properties[_propertyId];
        prop.rentPrice = _newRentPrice;
    }

    function withdrawBalance() public {
        // Only the contract owner can withdraw the balance
        require(msg.sender == properties[1].owner, "Only owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }
}
