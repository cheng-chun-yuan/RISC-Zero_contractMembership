// Copyright 2023 RISC Zero, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {IBonsaiRelay} from "bonsai/IBonsaiRelay.sol";
import {BonsaiLowLevelCallbackReceiver} from "bonsai/BonsaiLowLevelCallbackReceiver.sol";

/// @title A starter application using Bonsai through the on-chain relay.
/// @dev This contract demonstrates one pattern for offloading the computation of an expensive
//       or difficult to implement function to a RISC Zero guest running on Bonsai.
contract BonsaiStarterLowLevel is BonsaiLowLevelCallbackReceiver {
    // Cache of the results calculated by our guest program in Bonsai.
    mapping(address => bool) public membershipCache;

    // The image id of the only binary we accept callbacks from
    bytes32 public immutable fibImageId;

    /// @notice Initialize the contract, binding it to a specified Bonsai relay and RISC Zero guest image.
    constructor(IBonsaiRelay bonsaiRelay, bytes32 _fibImageId) BonsaiLowLevelCallbackReceiver(bonsaiRelay) {
        fibImageId = _fibImageId;
    }

    event GetMembershipCallback(address indexed n, bool result);

    /// @notice Returns nth number in the MEMBERSHIP sequence.
    /// @dev The sequence is defined as 1, 1, 2, 3, 5 ... with MEMBERSHIP(0) == 1.
    ///      Only precomputed results can be returned. Call calculate_MEMBERSHIP(n) to precompute.
    function  membership(address n) external view returns (bool) {
        bool result =  membershipCache[n];
        return result;
    }

    /// @notice Callback function logic for processing verified journals from Bonsai.
    function bonsaiLowLevelCallback(bytes calldata journal, bytes32 imageId) internal override returns (bytes memory) {
        require(imageId == fibImageId);
        (address n, bool result) = abi.decode(journal, (address, bool));
        emit GetMembershipCallback(n, result);
        membershipCache[n] = result;
        return new bytes(0);
    }

    /// @notice Sends a request to Bonsai to have have the nth MEMBERSHIP number calculated.
    /// @dev This function sends the request to Bonsai through the on-chain relay.
    ///      The request will trigger Bonsai to run the specified RISC Zero guest program with
    ///      the given input and asynchronously return the verified results via the callback below.
    function getMembership(address n) external {
        bonsaiRelay.requestCallback(
            fibImageId, abi.encode(n), address(this), this.bonsaiLowLevelCallbackReceiver.selector, 30000
        );
    }
}
