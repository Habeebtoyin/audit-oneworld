// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {Blspool} from "../src/contracts/Blspool.sol";

contract BlspoolTest is Test {
    //the contract you are testing
    Blspool _contract;

    function setUp() public {
        _contract = new Blspool(
            "ARG1",
            "ARG2",
            "ARG3"
        );
    }

    // Test that the contract was deployed with the correct constructor arguments
    //This is just an example of a test, you can customize this to your needs
    function testConstructorArgs() public {
        assertEq(_contract.arg1(), "ARG1");
        assertEq(_contract.arg2(), "ARG2");
        assertEq(_contract.arg3(), "ARG3");
    }

    function TestDepositETH() external {
        
        
    }
}
