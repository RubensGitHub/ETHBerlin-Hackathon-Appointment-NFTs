const { ethers } = require('hardhat');
const { expect } = require('chai');

//This tests covers the base functionality. It asserts that
//1) the doctor can mint appointments and have them for sale in the market place
//2) Alice can buy a specific one 
//3) Alice can sell it again
//4) Bob can by it from her

describe('Hackathon tests', function () {
    let doctor, alice, bob;

    // Pool has 1000 ETH in balance
    const ETHER_START_BALANCE = ethers.utils.parseEther('1');

    let contract_address;
    let tokenIdArray;
    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [doctor, alice, bob] = await ethers.getSigners();

        const appointmentNFTFactory = await ethers.getContractFactory('AppointmentScheduler', doctor);

        this.appointmentNFT = await appointmentNFTFactory.deploy();
        //await deployer.sendTransaction({ to: this.pool.address, value: ETHER_IN_POOL });
        
        //const appointmentSchedulerInstance = await appointmentNFTFactory.deploy();
        contract_address = this.appointmentNFT.address;

        const activeItems = await this.appointmentNFT.activeItems();

        //assert.equal(activeItems.length, 0, "Items list wasn't empty");
    });

    it('Doctor creates a schedule, thereby releasing the NFT appointments on the market place', async function () {

    //expect(bobsAppointments.length).to.equal(1);        
    await this.appointmentNFT.connect(doctor).setApprovalForAll(this.appointmentNFT.address, true);
    
    let activeItemsBefore = await this.appointmentNFT.activeItems();
    //There is nothing at the marketplace at the beginning
    expect(activeItemsBefore.length).to.equal(0);

    await this.appointmentNFT.connect(doctor).scheduleTime(1665993600, 30, 500 );
    await this.appointmentNFT.connect(doctor).scheduleTime(1665995400, 30, 500 );
    await this.appointmentNFT.connect(doctor).scheduleTime(1665997200, 30, 500 );
    await this.appointmentNFT.connect(doctor).scheduleTime(1665999000, 30, 500 );
    await this.appointmentNFT.connect(doctor).scheduleTime(1666000800, 30, 500 );

    let activeItemsAfter = await this.appointmentNFT.activeItems();
    
    //All 5 appointments are now active for sale in the marketplace
    expect(activeItemsAfter.length).to.equal(5);
    
    });

    it('Alice buys an appointment', async function(){
    let tokenId = 1;
    let userOwnedAppointments = await this.appointmentNFT.connect(alice).userOwnedAppointments(alice.address);
    let addressBefore = await this.appointmentNFT.ownerOf(tokenId);

    //Alice doesnt own any NFT-appointments to begin with
    expect(userOwnedAppointments.length).to.equal(0);
    
    await this.appointmentNFT.connect(alice).buyAppointment(tokenId, { value: 500 });
    let addressAfter = await this.appointmentNFT.ownerOf(tokenId);
    userOwnedAppointments = await this.appointmentNFT.userOwnedAppointments(alice.address);
    
    //Alice now owns an NFT
    expect(userOwnedAppointments.length).to.equal(1);
    
    //The owner changed
    expect(addressAfter === alice.address).to.equal(true);
    });

    it('Alice sells her appointment', async function(){
    let tokenId = 1;

    let activeItemsBefore = await this.appointmentNFT.activeItems();
    
    await this.appointmentNFT.connect(alice).sellAppointment(tokenId, 300);
    
    let activeItemsAfter = await this.appointmentNFT.activeItems();

    //The appointment is successfully listed for sale
    expect(activeItemsAfter.length - activeItemsBefore.length).to.equal(1);
    });

    it('Bob buys her appointment', async function(){
        let tokenId = 1;
        let bobsAppointments = await this.appointmentNFT.connect(bob).userOwnedAppointments(bob.address);
        //Bob doesnt own any NFTs at the beginning
        expect(bobsAppointments.length).to.equal(0);
    
        let activeItemsBefore = await this.appointmentNFT.activeItems();
        await this.appointmentNFT.connect(bob).buyAppointment(tokenId, {value: 300});
        activeItemsAfter = await this.appointmentNFT.activeItems();
        
        //The appointment is no longer active on sale in the market place
        expect(activeItemsBefore.length - activeItemsAfter.length).to.equal(1);

        bobsAppointments = await this.appointmentNFT.connect(bob).userOwnedAppointments(bob.address);
        //Bob now owns an appointment
        expect(bobsAppointments.length).to.equal(1);
        });
});
