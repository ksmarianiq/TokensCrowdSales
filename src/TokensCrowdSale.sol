// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./MyToken.sol";

contract TokensCrowdSale {
    // ERRORS

    error SalesHasNotStarted();
    error SalesHasEnded();
    error SalesHasNotEnded();
    error SalesHasClosed();
    error SalesLimit_HasBeenReached();
    error InsufficientBalance();
    error NumberOfTokensMustBe_GreaterThanZero();
    error CliffPeriod_IsNotOverYet();
    error NotOwner();

    // EVENTS

    event TokensPurchased(
        address indexed buyer,
        uint256 amount,
        uint256 totalContribution
    );

    event TokensUnlocked(address indexed buyer);

    // CONSTANT VARIABLES

    uint256 public constant MAX_TOKENS_TO_SELL = 500000 * 10 ** 18;
    uint256 public constant TOKENPRICE = 100; // 1 token = 0.001 ETH

    // IMMUTABLE VARIABLE

    MyToken public immutable i_token;

    // STORAGE VARIABLES
    address public s_owner;
    uint256 public s_tokensSold;
    uint256 public maxTokensToSell;
    uint256 public s_startTime;
    uint256 public s_deadline;
    bool public s_isCrowdSaleClosed;
    uint256 public s_cliffDuration;
    uint256 public s_vestingDuration;
    mapping(address => uint256) public s_contributions;
    mapping(address => uint256) public s_vestingSchedule;

    constructor(
        uint256 _initialSupply,
        uint256 _startTime,
        uint256 _deadline,
        uint256 _cliffDuration,
        uint256 _vestingDuration
    ) {
        require(MAX_TOKENS_TO_SELL <= _initialSupply);

        s_owner = msg.sender;
        i_token = new MyToken(_initialSupply);
        s_startTime = _startTime;
        s_deadline = _deadline;
        s_tokensSold = 0;
        s_isCrowdSaleClosed = false;
        s_cliffDuration = _cliffDuration;
        s_vestingDuration = _vestingDuration;
    }

    function purchaseTokens(uint256 _numberOfTokens) external payable {
        if (s_isCrowdSaleClosed) {
            revert SalesHasClosed();
        }

        if (s_startTime > block.timestamp) {
            revert SalesHasNotStarted();
        }

        if (s_deadline < block.timestamp) {
            revert SalesHasEnded();
        }

        if (_numberOfTokens == 0) {
            revert NumberOfTokensMustBe_GreaterThanZero();
        }

        if (s_tokensSold + _numberOfTokens > MAX_TOKENS_TO_SELL) {
            revert SalesLimit_HasBeenReached();
        }
        uint256 weiAmount = _numberOfTokens / TOKENPRICE;

        if (msg.value < weiAmount) {
            revert InsufficientBalance();
        }

        s_contributions[msg.sender] += msg.value;
        s_vestingSchedule[msg.sender] += _numberOfTokens;
        s_tokensSold += _numberOfTokens;
        i_token.transfer(msg.sender, (_numberOfTokens * 20) / 100); // 20% TGE
        emit TokensPurchased(
            msg.sender,
            _numberOfTokens,
            s_contributions[msg.sender]
        );
    }

    function unlockTokens() public {
        if (block.timestamp < s_deadline + s_cliffDuration) {
            revert CliffPeriod_IsNotOverYet();
        }

        uint256 vestedTokens = calculateVestedTokens(msg.sender);
        require(vestedTokens > 0, "No tokens to unlock");

        s_vestingSchedule[msg.sender] -= vestedTokens;
        i_token.transfer(msg.sender, vestedTokens);
        emit TokensUnlocked(msg.sender);
    }

    function calculateVestedTokens(
        address beneficiary
    ) public view returns (uint256) {
        uint256 totalAllocation = s_vestingSchedule[beneficiary];
        if (totalAllocation == 0) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - s_deadline - s_cliffDuration;
        uint256 vestedTokens = (totalAllocation * elapsedTime) /
            s_vestingDuration;

        if (elapsedTime >= s_vestingDuration) {
            vestedTokens = totalAllocation - ((totalAllocation * 20) / 100); // 80% vested
        } else {
            vestedTokens = vestedTokens - ((totalAllocation * 20) / 100); // 20% TGE
        }

        return vestedTokens;
    }

    function closeCrowdsale() public {
        if (msg.sender != s_owner) {
            revert NotOwner();
        }
        s_isCrowdSaleClosed = true;
    }

    function withdrawEther() external {
        if (msg.sender != s_owner) {
            revert NotOwner();
        }

        if (s_deadline > block.timestamp) {
            revert SalesHasNotEnded();
        }
        payable(s_owner).transfer(address(this).balance);
    }

    function getContribution(address buyer) public view returns (uint256) {
        return s_contributions[buyer];
    }
}
