// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AppointmentScheduler is ERC721, Ownable {
    
    using Counters for Counters.Counter; //TODO

  
   struct Appointment { 
      string date;
      string time;
      uint duration; //in minutes
   }
  

  mapping (uint => Appointment) appointments;
  constructor() ERC721("DoctorAppointment", "DA") {}


  function getInfo(uint tokenId) public view {
      return appointments[tokenId];
  }

  //Doctor creates a schedule
  function scheduleTime(string date, string time, uint duration) public returns (uint256) onlyOwner{
        tokenCounter.increment();
        uint256 newItemId = tokenCounter.current();
        
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, msg.sender);    //TODO: Needed? Or address(this)?

        Appointment appointment = new Appointment(date, time, duration);

        doctorTokenCounter.increment();
        uint doctorCounter = doctorTokenCounter.current();
        appointments[doctorCounter] = appointment;

        return newItemId;
    }

  
}