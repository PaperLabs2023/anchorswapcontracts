// SPDX-License-Identifier: MIT

import "./IAMM.sol";
import "./StableAlgorithm.sol";
import "./interfaces/ILPToken.sol";
import "./IERC20.sol";


pragma solidity ^0.8.9;

contract Pools{

    IAMM amm;
    uint ONE_ETH = 10**18;

    struct POOL{
        address lptokenAddr;
        uint [2] lpInfo;
    }

    

    constructor(address _amm){
        amm = IAMM(_amm);

    }

    function resetAmm(address _amm) public {
        amm = IAMM(_amm);
    }

    function profitPerYear(address _lpAddr) public view returns(uint)
    {
        //amm.getLpProfit(_lpAddr);
        uint duration = block.timestamp - amm.getLpCreatedTime(_lpAddr);
        return amm.getLpProfit(_lpAddr) * 86400 * 365 / duration;

    }

    function getStablePoolData(address _tokenA, address _tokenB) public view returns(address lptokenAddr,uint reserveA, uint reserveB, uint oneTokenAPrice){
        
    }

    function getAllStableLpTokenInfo() public view returns(address[] memory, uint[] memory,uint[] memory,uint[] memory) {

        uint listLength = amm.getStableLpTokenLength();

        uint[]  memory reserveAArray = new uint[](listLength);
        uint[]  memory reserveBArray = new uint[](listLength);
        //uint[]  memory price = new uint[](listLength);
        uint[]  memory profit = new uint[](listLength); 
        address[] memory lpArray = new address[](listLength);


        for(uint i ; i < listLength ; i ++){
            address lpAddr = amm.getStableLptokenList(i);
            address [2] memory tokenAB = amm.lpInfo(lpAddr);
            reserveAArray[i] = amm.getReserve(lpAddr, tokenAB[0]);
            reserveBArray[i] = amm.getReserve(lpAddr, tokenAB[1]);
            lpArray[i] = lpAddr;
            //(, ,price[i]) = cacalTokenOutAmountWithStableCoin(tokenAB[0], tokenAB[1],parameter);
            profit[i] = profitPerYear(lpAddr) * ONE_ETH / reserveAArray[i] + reserveBArray[i];

        }

        return(lpArray,reserveAArray,reserveBArray,profit);

        
    }

     function cacalTokenOutAmountWithStableCoin(address _tokenIn, address _tokenOut, uint _amountIn) public view returns(uint reserveIn,uint reserveOut,uint amountOut){
        require(_amountIn > 0, "amount in = 0");
        require(_tokenIn != _tokenOut);

        address lptokenAddr = amm.getStableLptoken(_tokenIn,_tokenOut);
        reserveIn = amm.getReserve(lptokenAddr,_tokenIn);
        reserveOut = amm.getReserve(lptokenAddr,_tokenOut);



        //交易税收 
        uint amountInWithFee = (_amountIn * (10000-amm.getUserFee())) / 10000;
        //amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);
        amountOut = calOutput(amm.getA(lptokenAddr),reserveIn + reserveOut, reserveIn,amountInWithFee);




    }


    function calOutAmount(uint A, uint D, uint X)public pure returns(uint)
    {
        //return  (4*A*D*D*X+calSqrt(A, D, X) -4*X-4*A*D*X*X) / (8*A*D*X);
        uint a = 4*A*D*X+D*calSqrt(A, D, X)-4*A*X*X-D*X;
        //uint amountOut2 = y - amountOut1;
        return a/(8*A*X);

    }

    function calOutput(uint A, uint D, uint X,uint dx)public pure returns(uint)
    {
        //D = D * 10**18;
        //X = X * 10**18;
        //dx = dx* 10**18;
        uint S = X + dx;
        uint amount1 = calOutAmount(A, D, X);
        uint amount2 = calOutAmount(A, D, S);

        //uint amountOut2 = y - amountOut1;
        return amount1 - amount2;

    }

    


    function calSqrt(uint A, uint D, uint X)public pure returns(uint)
    {
        //uint T = t(A,D,X);
        //uint calSqrtNum = _sqrt((X*(4+T))*(X*(4+T))+T*T*D*D+4*T*D*D-2*X*T*D*(4+T));
        //return calSqrtNum;
        (uint a, uint b) = (4*A*X*X/D+X,4*A*X);
        uint c;
        if(a>=b){
            c = a -b;
        }else{
            c = b-a;
        }

        return _sqrt(c*c+4*D*X*A);

    }




    function _sqrt(uint y) public pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
