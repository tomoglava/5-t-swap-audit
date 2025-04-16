//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TSwapPool } from "../../src/TSwapPool.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { Test, console2 } from "forge-std/Test.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    address liquidityProvider = makeAddr("liquidityProvider");
    address swapper = makeAddr("swaaper");

    // Ghost variables
    int256 startingX;
    int256 startingY;

    int256 expectedDeltaX;
    int256 expectedDeltaY;

    int256 deltaX;
    int256 deltaY;

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(_pool.getWeth());
        poolToken = ERC20Mock(_pool.getPoolToken());
    }

    //deposit, swapExactOutput - those two functions are the main ones we will be testing

    function swapPoolTokenForWethBasedOnOutputWeth(uint256 outputWeth) public {
        outputWeth = bound(outputWeth, 0, type(uint64).max);
        if (outputWeth >= weth.balanceOf(address(pool))) {
            return;
        }

        // we are looking at deltaX here
        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth, poolToken.balanceOf(address(pool)), weth.balanceOf(address(pool))
        );

        if (poolTokenAmount >= type(uint64).max) {
            return;
        }

        startingX = int256(poolToken.balanceOf(address(this)));
        startingY = int256(weth.balanceOf(address(this)));

        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(poolTokenAmount));
        expectedDeltaY = int256(-1) * int256(outputWeth);

        if (poolToken.balanceOf(swapper) < poolTokenAmount) {
            poolToken.mint(swapper, poolTokenAmount - poolToken.balanceOf(swapper) + 1);
        }

        vm.startPrank(swapper);
        poolToken.approve(address(pool), type(uint256).max);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        vm.stopPrank();

        uint256 newX = poolToken.balanceOf(address(this));
        uint256 newY = weth.balanceOf(address(this));

        // check that the pool has the right amount of tokens
        deltaX = int256(newX) - int256(startingX);
        deltaY = int256(newY) - int256(startingY);
    }

    function deposit(uint256 wethAmount) public {
        // let's' assume that it's a "reasnoble" amount
        // we want to avoid overflowing the pool

        wethAmount = bound(wethAmount, 0, type(uint64).max);
        // X is ERC20 token
        // Y is WETH

        startingX = int256(poolToken.balanceOf(address(this)));
        startingY = int256(weth.balanceOf(address(this)));

        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(wethAmount));
        expectedDeltaY = int256(wethAmount);

        //deposit
        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        poolToken.mint(liquidityProvider, uint256(expectedDeltaX));
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);

        pool.deposit(wethAmount, 0, uint256(expectedDeltaX), uint64(block.timestamp));
        vm.stopPrank();

        uint256 newX = poolToken.balanceOf(address(this));
        uint256 newY = weth.balanceOf(address(this));

        // check that the pool has the right amount of tokens
        deltaX = int256(newX) - int256(startingX);
        deltaY = int256(newY) - int256(startingY);
    }
}
