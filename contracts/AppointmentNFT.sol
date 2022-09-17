// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AppointmentScheduler is ERC721, Ownable {
    
   using Counters for Counters.Counter; //TODO

   Counters.Counter doctorTokenCounter;

  
   struct Appointment { 
      string date;
      uint time; //unix timestamp
      uint duration; //in minutes
      uint price; //in wei
   }
  

  mapping (uint => Appointment) appointments;
  constructor() ERC721("DoctorAppointment", "DA") {}


  function getInfo(uint tokenId) public view {
      return appointments[tokenId];
  }

  //Doctor creates a schedule
  function scheduleTime(string date, string time, uint duration, price) public returns (uint256) onlyOwner{
        tokenCounter.increment();
        uint256 newItemId = tokenCounter.current();
        
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, msg.sender);    //TODO: Needed? Or address(this)?

        Appointment appointment = new Appointment(date, time, duration);

        doctorTokenCounter.increment();
        uint doctorCounter = doctorTokenCounter.current();
        appointments[doctorCounter] = appointment;

        return newItemId;
    }

    function sellAppointment(uint tokenId, uint price){
        //TODO: asser retuirements
        appointment appointmentToSell = appointments[tokenId];
        
        require(appointmentToSell.price >= price);
        require(appointment.time > block.timestamp);


        approve(address(this), tokenId);
        //TODO Sellorder of some kind
    }

    function buyAppointment(tokenId) payable{

    }

    function getAppointmentForSale() public view{
        
    }
 
}