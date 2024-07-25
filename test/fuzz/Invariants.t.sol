//SPDX-License-Identifier:MIT

// What our invariants ?

// 1. Total supply of dsc should be less than collateral

// 2. Getter view functions should never revert <- evergreen invariant

pragma solidity ^0.8.18;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import{DeployDSC} from "../../script/DeployDSC.s.sol";
import{HelperConfig} from "../../script/HelperConfig.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {Handler} from '../fuzz/Handler.t.sol';


contract InvariantsTest is StdInvariant , Test {
    DeployDSC deployer ;
    DSCEngine dscEngine ;
    DecentralizedStableCoin dsc ;
    HelperConfig helperConfig;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc,dscEngine,helperConfig) = deployer.run();
        (, , weth , wbtc ,) = helperConfig.activeNetworkConfig();
        handler = new Handler(dscEngine , dsc);
        targetContract(address(handler));
    }

    function invariant_protocalMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

        uint256 wethValue = dscEngine.getUsdValue(weth , totalWethDeposited);
        uint256 wbtcValue = dscEngine.getUsdValue(weth , totalWbtcDeposited);

        assert(wbtcValue + wethValue >= totalSupply);

    }
}