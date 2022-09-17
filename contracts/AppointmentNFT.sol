// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


contract AppointmentScheduler is ERC721, Ownable {
    // An appointment is being resold by a patient
    event ItemListed(uint256 indexed tokenId, uint256 price);

    // Doctor creates a schedule
    event AppointmentCreated(uint256 indexed tokenId);

    // An appointment has been sold
    event AppointmentSold(uint256 indexed tokenId);

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct Appointment {
        uint256 time; //unix timestamp
        uint256 duration; //in minutes
        uint256 lastPrice; //in wei
        uint256 currentSellPrice; //in wei, set to 0 in case not used
    }

    uint listedPercentage = 1; // In percent

    uint256 tokenIdCounter;

    // tokenIds => Appointment-metadata
    mapping(uint256 => Appointment) appointments;
    mapping(address => EnumerableSetUpgradeable.UintSet) ownedAppointments;

    EnumerableSetUpgradeable.UintSet private _activeIds;

    constructor() ERC721("DoctorAppointment", "DA") {}

    function getInfo(uint256 tokenId) public view returns (Appointment memory) {
        return appointments[tokenId];
    }

    //Doctor creates a schedule
    function scheduleTime(
        uint256 time,
        uint256 duration,
        uint256 price
    ) public onlyOwner returns (uint256) {
        tokenIdCounter++;
        _safeMint(msg.sender, tokenIdCounter);

        Appointment memory appointment = Appointment(time, duration, price, 0);
        emit AppointmentCreated(tokenIdCounter);

        appointments[tokenIdCounter] = appointment;
        ownedAppointments[msg.sender].add(tokenIdCounter);

        //Doctor also sells at the market place
        sellAppointment(tokenIdCounter, price);

        return tokenIdCounter;
    }

    function sellAppointment(uint256 tokenId, uint256 price) public {
        //assert requirements
        //tokem is owned by msg.sender
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this token!");
        
        //appointment exists
        require(appointments[tokenId].lastPrice != 0, "tokenId does not belong to any appointment. Did it expire?");
        Appointment memory appointmentToSell = appointments[tokenId];

        //originalprice was not smaller than this
        require(appointmentToSell.lastPrice >= price, "You can not sell the appointment for more than you bought it for!");

        //Appointment is still valid
        require(appointmentToSell.time > block.timestamp, "The appointment already expired!");

        //Appointment is not yet for sale yet
        //TODO: How about an updating of prices?
        require(appointmentToSell.currentSellPrice == 0, "Appointment is already for sale!");

        appointments[tokenId].currentSellPrice = price;
        approve(address(this), tokenId); // does this work?

        _activeIds.add(tokenId);
        emit ItemListed(tokenId, price);
    }

    function buyAppointment(uint256 tokenId) public payable {
        //assert requirements
        //appointment exists
        require(appointments[tokenId].lastPrice != 0, "tokenId does not belong to any appointment. Did it expire?");
        Appointment memory appointmentToSell = appointments[tokenId];

        //Still valid appointment
        require(appointmentToSell.time > block.timestamp, "The appointment already expired!");

        //For sale
        require(appointments[tokenId].currentSellPrice != 0, "Appointment is not for sale!");

        //Enough money provided
        require(appointments[tokenId].currentSellPrice <= msg.value, "Not enough ETH provided for payment of appointment!");

        //Remove from active set of sell-positions
        _activeIds.remove(tokenId);

        //award seller
        address _owner = ownerOf(tokenId);

        uint feesPortion = appointments[tokenId].currentSellPrice / 100 * listedPercentage;
        
        payable(_owner).transfer(appointments[tokenId].currentSellPrice - feesPortion);

        //possibly send remaining change to buyer
        uint256 change = appointments[tokenId].currentSellPrice - msg.value;
        if (change > 0) {
            payable(msg.sender).transfer(change);
        }

        //Transfer appointment to buyer
        safeTransferFrom(_owner, msg.sender, tokenId);
        
        appointments[tokenId].lastPrice = appointments[tokenId].currentSellPrice;
        appointments[tokenId].currentSellPrice = 0;
        
        ownedAppointments[_owner].remove(tokenIdCounter);
        ownedAppointments[msg.sender].add(tokenIdCounter);

        emit AppointmentSold(tokenId);
    }

    //In case the user directly sends the NFT to someone without using the market place, not tested
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        super._transfer(from,to,tokenId);
        ownedAppointments[from].remove(tokenId);
        ownedAppointments[to].add(tokenId);

        //If it was for sale, remove
        appointments[tokenId].currentSellPrice = 0;
        _activeIds.remove(tokenId);
    }

    function activeItems() public view returns (Appointment[] memory) {
        uint256 totalActive = _activeIds.length();

        Appointment[] memory items = new Appointment[](totalActive);

        for (uint256 i = 0; i < totalActive; i++) {
            items[i] = appointments[_activeIds.at(i)];
        }

        return items;
    }

    function usersListingIds(address user) public view returns (Appointment[] memory)
    {
        Appointment[] memory listingsOfUser = new Appointment[](ownedAppointments[user].length());

        for (uint256 i = 0; i < listingsOfUser.length; i++) {
            uint ownedTokenId = ownedAppointments[user].at(i);
            listingsOfUser[i] = appointments[ownedTokenId];
        }

        return listingsOfUser;
    }
}
