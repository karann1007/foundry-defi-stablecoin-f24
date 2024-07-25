//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;
    HelperConfig helperConfig;
    address weth;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;

    address public user = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (ethUsdPriceFeed,btcUsdPriceFeed, weth,,) = helperConfig.activeNetworkConfig();

        ERC20Mock(weth).mint(user, STARTING_ERC20_BALANCE);
    }


    /////////// CONSTRUCTOR TEST //////////////

    address[] public tokenAddresses ; 
    address[] public priceFeedAddress ;

    function testRevertsIfTokenLengthDoesntMAtchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddress.push(ethUsdPriceFeed);
        priceFeedAddress.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressAndPriceFeedAddressesMustBeOfSameLength.selector);
        new DSCEngine(tokenAddresses , priceFeedAddress ,address(dsc));
    }

    /////////////////// PRICE TEST ///////////

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedEthAmount = 30000e18;
        console.log("Reaching here");
        uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
        console.log(actualUsd);
        assertEq(actualUsd, expectedEthAmount);
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether ;            // USD amount in wei
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dscEngine.getTokenAmountFromUsd(weth ,  usdAmount);
        assertEq(expectedWeth,actualWeth);
    }

    //////////// DEPOSIT COLLATERAL TEST ////////////////

    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedToken() public {
        ERC20Mock ran = new ERC20Mock();
        ERC20Mock(ran).mint(user,AMOUNT_COLLATERAL);
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscEngine.depositCollateral(address(ran),AMOUNT_COLLATERAL);
        vm.stopPrank();

    }
    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth , AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }
    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral(){
        (uint256 totalDscMinted , uint256 collateralValueInUsd ) = dscEngine.getAccountInformation(user);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dscEngine.getTokenAmountFromUsd(weth , collateralValueInUsd);
        assertEq(totalDscMinted , expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL , expectedDepositAmount);
    }
}
