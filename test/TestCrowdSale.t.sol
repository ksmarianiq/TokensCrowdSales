// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/TokensCrowdSale.sol";

contract TestCrowdSale is Test {


        event TokensPurchased(
        address indexed buyer,
        uint256 indexed amount,
        uint256 totalContribution
    );

    event TokensUnlocked(address indexed buyer);

    address BUYER;
    uint256 constant INITIAL_SUPPLY = 1000000 * 10 ** 18;
    uint256 startTime = block.timestamp + 1 days;
    uint256 deadline = startTime + 10 days;
    uint256 cliffDuration = deadline + 30 days;
    uint256 vestingDuration = cliffDuration + 90 days;

    MyToken token;
    TokensCrowdSale crowdSale;

    function setUp() public {
        crowdSale = new TokensCrowdSale(
            INITIAL_SUPPLY,
            startTime,
            deadline,
            cliffDuration,
            vestingDuration
        );
        BUYER = makeAddr("BUYER");
    }

    function test_RevertWhen_UserWantBuyTokens_BeforeStartTime() public {
        vm.warp(crowdSale.s_startTime() - 1 days);
        uint256 amount = 10 * 10 ** 17; // Réduire la quantité
        uint256 ethAmount = amount / crowdSale.TOKENPRICE();
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        vm.expectRevert(TokensCrowdSale.SalesHasNotStarted.selector);
        crowdSale.purchaseTokens{value: ethAmount}(amount);
        vm.stopPrank();
    }

    function test_RevertWhen_UserWantBuyTokens_AfterDealine() public {
        vm.warp(crowdSale.s_deadline() + 1 days);
        uint256 amount = 10 * 10 ** 17; // Réduire la quantité
        uint256 ethAmount = amount / crowdSale.TOKENPRICE();
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        vm.expectRevert(TokensCrowdSale.SalesHasEnded.selector);
        crowdSale.purchaseTokens{value: ethAmount}(amount);
        vm.stopPrank();
    }

    function test_RevertWhen_UserWantBuyTokens_WithZeoTokens() public {
        vm.warp(crowdSale.s_deadline());

        uint256 amount = 10 * 10 ** 17; // Réduire la quantité
        uint256 ethAmount = amount / crowdSale.TOKENPRICE();
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        vm.expectRevert(
            TokensCrowdSale.NumberOfTokensMustBe_GreaterThanZero.selector
        );
        crowdSale.purchaseTokens(0);
        vm.stopPrank();
    }

    function test_RevertWhen_MaxTokensToSell_IsExceeded() public {
        vm.warp(crowdSale.s_deadline());

        uint256 amount = crowdSale.MAX_TOKENS_TO_SELL() + 1; // Réduire la quantité
        uint256 ethAmount = amount / crowdSale.TOKENPRICE();
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        vm.expectRevert(TokensCrowdSale.SalesLimit_HasBeenReached.selector);
        crowdSale.purchaseTokens{value: ethAmount}(amount);
        vm.stopPrank();
    }

    function test_RevertWhen_BalanceInsufficient() public {
        vm.warp(crowdSale.s_deadline());

        uint256 amount = 10 * 10 ** 17; // Réduire la quantité
        uint256 ethAmount = amount / crowdSale.TOKENPRICE() - 1;
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        vm.expectRevert(TokensCrowdSale.InsufficientBalance.selector);
        crowdSale.purchaseTokens{value: ethAmount}(amount);
        vm.stopPrank();
    }

    function test_ExpectEmit_SuccessfullPurchaseTokens() public{
          vm.warp(crowdSale.s_deadline());

        uint256 amount = 10 * 10 ** 17; 
        uint256 ethAmount = amount / crowdSale.TOKENPRICE();
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        vm.expectEmit(true, true, false, false);
        emit TokensPurchased(BUYER,amount , ethAmount);
        crowdSale.purchaseTokens{value: ethAmount}(amount);
        vm.stopPrank();
    }
    function test_PurchaseTokens() public payable {
        vm.warp(crowdSale.s_deadline());
        uint256 amount = 10 * 10 ** 17; // Réduire la quantité
        uint256 ethAmount = amount / crowdSale.TOKENPRICE();
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        crowdSale.purchaseTokens{value: ethAmount}(amount);
        vm.stopPrank();
      
       assert(crowdSale.getContribution(BUYER)== ethAmount);
       uint256 tgeTokens = (amount * 20) / 100;
        assert(crowdSale.i_token().balanceOf(BUYER) == tgeTokens);
        assert(
            crowdSale.s_vestingSchedule(BUYER)==
           ( amount )
        );
        
    }
    

    function test_revertWhen_UserWantUnlockTokens_BeforeCliffPeriod() public{
        vm.warp(crowdSale.s_cliffDuration() - 1 days);
        vm.startPrank(BUYER);
        vm.expectRevert(TokensCrowdSale.CliffPeriod_IsNotOverYet.selector);
        crowdSale.unlockTokens();
        vm.stopPrank();
    }

  function test_ExpectEmit_SuccessfullUnlockTokens() public{
            vm.warp(crowdSale.s_deadline());
        uint256 amount = 10 * 10 ** 17; 
        uint256 ethAmount = amount / crowdSale.TOKENPRICE();
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        crowdSale.purchaseTokens{value: ethAmount}(amount);

        vm.warp(crowdSale.s_cliffDuration() + crowdSale.s_vestingDuration() );
        vm.startPrank(BUYER);
        vm.expectEmit(true, false, false, false);
        emit TokensUnlocked(BUYER);
        crowdSale.unlockTokens();
        vm.stopPrank();
       
        
    }
   function test_UnlockTokens() public{
          vm.warp(crowdSale.s_startTime());
        uint256 amount = 10 * 10 ** 17; 
        uint256 ethAmount = amount / crowdSale.TOKENPRICE();
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        crowdSale.purchaseTokens{value: ethAmount}(amount);
    

        vm.warp(crowdSale.s_cliffDuration() + crowdSale.s_vestingDuration() );
        vm.startPrank(BUYER);
        crowdSale.unlockTokens();
        vm.stopPrank();

    }


    function test_RevertWhen_UserIsNotOwner_WantWithdrawEther() public{
        vm.startPrank(BUYER);
        vm.expectRevert(TokensCrowdSale.NotOwner.selector);
        crowdSale.withdrawEther();
    }

    function test_WithdrawEther() public{

        vm.warp(crowdSale.s_deadline());
        uint256 amount = 10 * 10 ** 17; 
        uint256 ethAmount = amount / crowdSale.TOKENPRICE();
        vm.deal(BUYER, ethAmount);
        vm.startPrank(BUYER);
        crowdSale.purchaseTokens{value: ethAmount}(amount);
        vm.stopPrank();

        vm.warp(crowdSale.s_deadline() + 1 days);
        vm.startPrank(crowdSale.s_owner());
        crowdSale.withdrawEther();
        vm.stopPrank();

        
    }

    function test_RevertWhen_UserIsNotOwner_WantCloseCrowdSale() public {
        vm.prank(BUYER);
        vm.expectRevert(TokensCrowdSale.NotOwner.selector);
        crowdSale.closeCrowdsale();

    }

    function test_RevertWhen_CrowdSaleHasClosed() public{
        vm.startPrank(crowdSale.s_owner());
        crowdSale.closeCrowdsale();
        vm.stopPrank();

        vm.expectRevert();
     
        vm.deal(BUYER, 1 ether);
        vm.startPrank(BUYER);
        crowdSale.purchaseTokens{value: 1 ether}(10000 * 10**18);
        vm.stopPrank();
    }
}
