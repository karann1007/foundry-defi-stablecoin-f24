//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test , console} from '../../lib/forge-std/src/Test.sol';
import {DecentralizedStableCoin} from '../../src/DecentralizedStableCoin.sol';
import {DSCEngine} from '../../src/DSCEngine.sol';
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";

contract Handler is Test {

    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    ERC20Mock weth;
    ERC20Mock wbtc;

    address[] public usersWithCollateralDeposited ;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;

    constructor(DSCEngine _dsce , DecentralizedStableCoin _dsc) {
        dsce = _dsce;
        dsc = _dsc;
        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // Mint DSC

    function mintDSC(uint256 amount , uint256 addressSeed) public {
        if(usersWithCollateralDeposited.length == 0){
            return;
        }
        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length];
        amount = bound(amount , 1 , MAX_DEPOSIT_SIZE);
        (uint256 totalDscMinted ,  uint256 collateralValueInUsd) = dsce.getAccountInformation(msg.sender);
        uint256 maxDscToMint = (collateralValueInUsd / 2 ) - totalDscMinted;
        if(maxDscToMint < 0) {
            return;
        }
        amount = bound(amount , 0 ,maxDscToMint);
        if(amount==0) {
            return ;
        }
        vm.startPrank(sender);
        dsce.mintDSC(amount);
        vm.stopPrank();
    }

    // Deposit Collateral

    function depositCollateralNow(uint256 collateralSeed , uint256 amountCollateral) public {
        console.log("-----------------------------------1");
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral , 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender , amountCollateral);
        collateral.approve(address(dsce) , amountCollateral);
        console.log("-----------------------------------2");
        dsce.depositCollateral(address(collateral) , amountCollateral);
        vm.stopPrank();
        usersWithCollateralDeposited.push(msg.sender);
    }

    //Redeem Collateral

    function redeemCollateral(uint256 collateralSeed , uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(msg.sender,address(collateral));
        amountCollateral = bound(amountCollateral , 0 , maxCollateralToRedeem);
        if(amountCollateral == 0) {
            return;
        }
        dsce.redeemCollateral(address(collateral),amountCollateral);
    }

    // Helper function

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock) {
        if(collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }

}