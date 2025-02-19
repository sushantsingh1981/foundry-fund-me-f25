// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
//import {MockV3Aggregator} from "../test/mocks/mockV3Aggregator.sol";

contract FundMetest is Test{

    FundMe fundMe;

    address USER = makeAddr("user"); // making fake user 
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether; // sending eth to fake user
    uint256 constant GAS_PRICE = 1;
    function setUp () external {
    
    // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
    vm.deal(USER, STARTING_BALANCE); //giving fake user eth

    }

    function testMinimumUsdIsFive() public view{

        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() public view{

        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view{

        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailWithoutEnoughEth() public  {

        vm.expectRevert();

        fundMe.fund();

    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // next TX will be sent by USER we created
        fundMe.fund{value : SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
       vm.prank(USER); // next TX will be sent by USER we created
        fundMe.fund{value : SEND_VALUE}(); 
        _;
    }

    function testAddsFunderToArrayOfFunders() public funded {
        
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();

    }

    function testWithdrawWithSingleFunder()  public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        uint256 gasStart = gasleft(); // send 1000 gas
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());// used 200 gas
        fundMe.withdraw();
        uint256 gasEnd = gasleft();// 800 gas left
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance+startingOwnerBalance,endingOwnerBalance);
        
    }

     function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunder = 10;
        uint160  startingFunderIndex = 2;
        for (uint160  i= startingFunderIndex;i<numberOfFunder;i++) {
            //vm.prank new address
            //vm.deal new address
            // fund the fundMe
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

       vm.startPrank(fundMe.getOwner());

        fundMe.cheaperWithdraw();

        vm.stopPrank();

        assert(address(fundMe).balance==0);
        assert(startingFundMeBalance+startingOwnerBalance == fundMe.getOwner().balance);

    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunder = 10;
        uint160  startingFunderIndex = 2;
        for (uint160  i= startingFunderIndex;i<numberOfFunder;i++) {
            //vm.prank new address
            //vm.deal new address
            // fund the fundMe
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

       vm.startPrank(fundMe.getOwner());

        fundMe.withdraw();

        vm.stopPrank();

        assert(address(fundMe).balance==0);
        assert(startingFundMeBalance+startingOwnerBalance == fundMe.getOwner().balance);

    }

}