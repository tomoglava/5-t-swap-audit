//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";

import { ERC20Mock } from "../mocks/ERC20Mock.sol";

contract Invariant is StdInvariant, Test {
    ERC20Mock poolToken;
    ERC20Mock weth;

    PoolFactory factory;
    TSwapPool pool; // poolToken / weth

    int256 constant STARTING_X = 100e18;
    int256 constant STARTING_Y = 50e18;

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        //create initial x & y balances
        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        pool.deposit(uint256(STARTING_Y), uint256(STARTING_Y), uint256(STARTING_X), uint64(block.timestamp));
    }

    function statefulFuzz_constantProductFormulaStaysTheSame() public {
        // assert() what?

        // The change in the pool should follow this formula:
        // delata(x) = (beta / (1 - beta)) * x
        // how to code this?

        // anytime anyone exact swap, we should check the balance of x before and after the swap
        // we use handler to track the balance of x before and after the swap
    }
}
