// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


contract AppointmentScheduler is ERC721, Ownable {
    // An appointment is being resold by a patient
    event ItemListed(uint256 indexed tokenId, uint256 price);

    // Doctor creates a schedule
    event AppointmentCreated(uint256 indexed tokenId);

    // An appointment has been sold
    event AppointmentSold(uint256 indexed tokenId);

    uint256 tokenIdCounter;

    struct Appointment {
        uint256 time; //unix timestamp
        uint256 duration; //in minutes
        uint256 lastPrice; //in wei
        uint256 currentSellPrice; //in wei, set to 0 in case not used
    }

    // tokenIds => Appointment-metadata
    mapping(uint256 => Appointment) appointments;
    mapping(address => EnumerableSetUpgrade.UintSet) ownedAppointments;

    EnumerableSetUpgradeable.UintSet private _activeIds;

    constructor() ERC721("DoctorAppointment", "DA") {}

    function getInfo(uint256 tokenId) public view {
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

        Appointment appointment = new Appointment(time, duration, price, 0);
        emit AppointmentCreated(tokenIdCounter);

        appointments[tokenIdCounter] = appointment;
        //Doctor also sells at the market place
        sellAppointment(tokenIdCounter, price);

        ownedAppointsments[msg.sender].add(tokenIdCounter);

        return tokenIdCounter;
    }

    function sellAppointment(uint256 tokenId, uint256 price) {
        //assert requirements
        //appointment exists
        require(appointments[tokenId] != 0);
        appointment appointmentToSell = appointments[tokenId];

        //originalprice was not smaller than this
        require(appointmentToSell.LastSellPrice >= price);

        //Appointment is still valid
        require(appointment.time > block.timestamp);

        //Appointment is not yet for sale yet
        //TODO: How about an updating of prices?
        require(appointmentToSell.currentSellPrice == 0);

        appointments[tokenId].currentSellPrice = price;
        approve(address(this), tokenId); // does this work?

        _activeIds.add(tokenId);
        emit ItemListed(tokenId, price);
    }

    function buyAppointment(uint256 tokenId, uint256 price) public payable {
        //assert requirements
        //appointment exists
        require(appointments[tokenId] != 0);
        appointment appointmentToSell = appointments[tokenId];

        //Still valid appointment
        require(appointment.time > block.timestamp);

        //For sale
        require(appointments[tokenId].currentSellPrice != 0);

        //Enough money provided
        require(appointments[tokenId].currentSellPrice <= msg.value);

        //Remove from active set of sell-positions
        _activeIds.remove(tokenId);

        //award seller
        address _owner = ownerOf(tokenId);

        _owner.transfer(appointments[tokenId].currentSellPrice);

        //possibly send remaining change to buyer
        uint256 change = appointments[tokenId].currentSellPrice - msg.value;
        if (change > 0) {
            msg.sender.transfer(change);
        }

        //Transfer appointment to buyer
        safeTransferFrom(_owner, msg.sender, tokenId);
        appointments[tokenId].LastSellPrice = appointments[tokenId]
            .currentSellPrice;
        appointments[tokenId].currentSellPrice = 0;

        ownedAppointsments[_owner].remove(tokenIdCounter);
        ownedAppointsments[msg.sender].add(tokenIdCounter);

        emit AppointmentSold(tokenId);
    }

    //In case the user directly sends the NFT to someone without using the market place, not tested
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        super._transfer(from,to,tokenId);
        ownedAppointments[from].remove(tokenId);
        ownedAppointments[to].add(tokenId);
    }

    function activeItems() public view returns (Appointment[] memory) {
        uint256 totalActive = _activeIds.length();

        Appointment[] memory items = new Appointment[](totalActive);

        for (uint256 i = 0; i < totalActive; i++) {
            items[i] = appointments[_activeIds.at(i)];
        }

        return items;
    }

    function usersListingIds(address user)
        public
        view
        returns (uint256[] memory)
    {
        Appointment[] memory listingsOfUser = new Appointment[](
            ownedAppointments[user].length()
        );

        for (uint256 i = 0; i < listingsOfUser.length; i++) {
            listingsOfUser[i] = ownedAppointments[user].at(i);
        }

        return listingsOfUser;
    }
}
