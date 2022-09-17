// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract AppointmentScheduler is ERC721, Ownable {
    
    // An appointment is being resold by a patient
    event ItemListed(
        uint256 indexed tokenId,
        uint256 price
    );

    // Doctor creates a schedule
    event AppointmentCreated(
        uint256 indexed tokenId
    );

    // An appointment has been sold
    event AppointmentSold(
        uint256 indexed tokenId
    );

   uint tokenIdCounter;

  
   struct Appointment { 
      uint time; //unix timestamp
      uint duration; //in minutes
      uint price; //in wei
      uint currentSellPrice; //set to 0 in case not used
   }
  

  //tokenIds => Appointment-metadata
  mapping (uint => Appointment) appointments;

  EnumerableSetUpgradeable.UintSet private _activeIds;
  
  constructor() ERC721("DoctorAppointment", "DA") {}

  function getInfo(uint tokenId) public view {
      return appointments[tokenId];
  }

  //Doctor creates a schedule
  function scheduleTime(uint time, uint duration, uint price) public onlyOwner returns (uint256){
        tokenIdCounter++;
        
        
        _safeMint(msg.sender, tokenIdCounter);
        _setTokenURI(tokenIdCounter, msg.sender);    //TODO: Needed? Or address(this)?

        Appointment appointment = new Appointment(time, duration, price, 0);

        appointments[tokenIdCounter] = appointment;
        
        emit AppointmentCreated(tokenId);

        return tokenIdCounter;
    }

    function sellAppointment(uint tokenId, uint price){
        //assert requirements
        //appointment exists
        require(appointments[tokenId] != 0);
        appointment appointmentToSell = appointments[tokenId];
        
        //originalprice was not smaller than this
        require(appointmentToSell.price >= price);

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

    function buyAppointment(uint tokenId, uint price) public payable{
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
        uint change = appointments[tokenId].currentSellPrice - msg.value;
        if(change > 0){
            msg.sender.transfer(change); 
        }
        
        //Transfer appointment to buyer
        safeTransferFrom(_owner, msg.sender, tokenId);
        appointments[tokenId].currentSellPrice = 0;

        emit AppointmentSold(tokenId);
        
    }

}