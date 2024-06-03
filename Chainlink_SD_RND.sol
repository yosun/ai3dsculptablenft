// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18; 

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract StableDiffusionSeedGenerator is VRFConsumerBaseV2, ConfirmedOwner {
    event SeedRequested(uint256 requestId);
    event SeedFulfilled(uint256 requestId, uint256 seed);

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 s_keyHash; // Chainlink VRF keyHash (get from Chainlink docs)
    uint32 s_callbackGasLimit = 500000; // Adjust based on network conditions
    uint16 s_requestConfirmations = 3; 
    uint32 constant NUM_WORDS = 1;  // Only need one random word

    struct SeedRequest {
        uint256 seed;
        bool fulfilled;
    }
    mapping(uint256 => SeedRequest) public s_requests;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash 
    ) 
        VRFConsumerBaseV2(vrfCoordinator)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
    }

    function requestSeed() external onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            NUM_WORDS
        );
        s_requests[requestId] = SeedRequest(0, false);
        emit SeedRequested(requestId);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 seed = randomWords[0] & 0xffffffff; // Mask to 32 bits
        s_requests[requestId] = SeedRequest(seed, true);
        emit SeedFulfilled(requestId, seed);
    }

    // Helper function
    function getSeed(uint256 requestId) external view returns (uint256) {
        require(s_requests[requestId].fulfilled, "Request not fulfilled");
        return s_requests[requestId].seed;
    }
}
