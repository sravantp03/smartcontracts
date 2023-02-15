// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

error Lottery__InsufficientETHFunded();
error Lottery__TransferFailed();
error Lottery__Closed();
error Lottery__UpKeepNotNeeded(
    uint256 currentBalance,
    uint256 playersCount,
    uint256 lotteryState
);

/**
 * @title Sample Lottery Contract
 * @author Sravan T P
 * @notice This contract is for creating a untamperable decentralized smart contract
 */

contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    // Types declaration

    enum LotteryState {
        OPEN,
        CALCULATING
    }

    // State Variables
    uint256 private immutable i_entraceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    LotteryState private s_lotteryState;

    address private s_recentWinner;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    // Events
    event LotteryEnter(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 _entranceFee,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint256 _interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entraceFee = _entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = _interval;
    }

    function enterLottery() public payable {
        // checking whether lottery is open before entering
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__Closed();
        }

        if (msg.value < i_entraceFee) {
            revert Lottery__InsufficientETHFunded();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Lottery__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        // when requesting random winner we update lottery state as calculating so that
        // no new player can join.
        s_lotteryState = LotteryState.CALCULATING;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address addressOfWinner = s_players[indexOfWinner];
        s_recentWinner = addressOfWinner;
        s_players = new address payable[](0); // resetting array after picking winner.
        s_lastTimeStamp = block.timestamp; // reseting timestamp by current time
        (bool success, ) = addressOfWinner.call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert Lottery__TransferFailed();
        }

        emit WinnerPicked(addressOfWinner);
        s_lotteryState = LotteryState.OPEN;
    }

    // view / pure functions

    function getEntranceFee() public view returns (uint256) {
        return i_entraceFee;
    }

    function getPlayer(uint256 _index) public view returns (address) {
        return s_players[_index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getTotalPlayers() public view returns (uint256) {
        return s_players.length;
    }
}
