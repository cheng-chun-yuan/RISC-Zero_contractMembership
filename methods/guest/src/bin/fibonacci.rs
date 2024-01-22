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

#![no_main]
use std::io::Read;

use ethabi::{ethereum_types::Address, ParamType, Token};
use risc0_zkvm::guest::env;

risc0_zkvm::guest::entry!(main);

fn membership(n: Address) -> bool {
    let array: [Address; 3] = [
        Address::from_slice(&[0x00; 20]), // Fake address 1
        Address::from_slice(&[0x01; 20]), // Fake address 2
        Address::from_slice(&[0x02; 20]), // Fake address 3
    ];
    array.iter().any(|&item| item == n)
}

fn main() {
    // Read data sent from the application contract.
    let mut input_bytes = Vec::<u8>::new();
    env::stdin().read_to_end(&mut input_bytes).unwrap();
    // Type array passed to `ethabi::decode_whole` should match the types encoded in
    // the application contract.
    let input = ethabi::decode_whole(&[ParamType::Address], &input_bytes).unwrap();
    let n: Address = input[0].clone().into_address().unwrap();
    // Run the computation.
    let result = membership(n);

    // Commit the journal that will be received by the application contract.
    // Encoded types should match the args expected by the application callback.
    env::commit_slice(&ethabi::encode(&[Token::Address(n), Token::Bool(result)]));
}
