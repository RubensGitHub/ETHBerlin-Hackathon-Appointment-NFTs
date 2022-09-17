

console.log("Alice decides to book an appointment at doctor A. She checks the schedule:");

//<call activeItems()>


console.log("The appointment at 10:00 am fits her best. She chooses to do the prepayment at a reduced price.");
console.log("While before the booking she does not own any appointment-NFTs:")

//call <userOwnedAppointments(alice-address)>

//call <userOwnedAppointments(alice-address)>
console.log("After the booking...")

//call <buyAppointment(tokenId)> from alice
console.log("... She now owns the NFT related to the booking!")
//call <userOwnedAppointments(alice-address)>

console.log("However, a few days later she realized she has to pick up her son from a hackathon. She is a bit mad that she chose the prepayment option, but at least she knows she can try to sell the appointment.")

console.log("Since there are only a few days left to the appointment, she sets the price quite a bit lower purchase price. She has a slight loss, but at least not the full amount.");


//call <sellAppointment(tokenId, price)> from alice

console.log("Her appointment is now listed in the market place.");

//call <activeItems()>

console.log("Bob logs in a few days later and sees a short-term appointment-slot at a reduced price available in the marketplace, sweet! He doesn't even need to have a awkward phone-call to book it.")


console.log("Bob buys the NFT-appointment");

//call <buyAppointment(tokenId)> from Bob

console.log("He owns the appointment:")
//call <userOwnedAppointments(bob-address)>

console.log("And Alice got at least the majority of the money back!")
//call <balanceOfAlice>