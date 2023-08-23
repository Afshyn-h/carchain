pragma solidity ^0.5.15;

import './IERC20.sol';
import './TransferHelper.sol';
contract exchange{
    
    mapping(address => mapping(address => bool))pair;
    mapping(address => uint256)AmoutToken1;
    mapping(address => uint256)AmountToken2;
    mapping(address => mapping(address => uint256))Price;
    mapping(address => address)pegTokens;
    
    address owner;
    constructor(address _owner)public {
        owner = _owner;
    }
    
    function createpair(address token1, uint256 amoutToken1, address token2, uint256 amoutToken2)public {
        require(msg.sender == owner);
        require(pair[token1][token2] == false &&  pair[token2][token1] == false);
         
        IERC20(token1).transfer(address(this), amoutToken1);
        IERC20(token2).transfer(address(this), amoutToken2);
        pair[token1][token2] = true;
        pair[token2][token1] = true;
        Price[token1][token2] = amoutToken1 * amoutToken2;
        Price[token2][token1] = amoutToken1 * amoutToken2;
        pegTokens[token1] = token2;
        pegTokens[token2] = token1;
        
        
          
    }
    
    function getTokenPrice(address token)public view returns(uint256, uint256){
        
        uint priceToken2 = IERC20(token).balanceOf(address(this))/IERC20(pegTokens[token]).balanceOf(address(this));
        uint priceToken = IERC20(pegTokens[token]).balanceOf(address(this))/IERC20(token).balanceOf(address(this));
        
        return(priceToken, priceToken2);
    }
    
    function mintToPool(address token, uint256 amoutToken)public{
        
        require(msg.sender == owner);
        require(IERC20(token).balanceOf(address(this))> 0);
        
         IERC20(token).transfer(address(this), amoutToken);
         Price[token][pegTokens[token]] =
         IERC20(token).balanceOf(address(this)) * IERC20(pegTokens[token]).balanceOf(address(this));
         
         Price[pegTokens[token]][token] =
         IERC20(token).balanceOf(address(this)) * IERC20(pegTokens[token]).balanceOf(address(this));
         
    }
    
    function burnFromPool(address token, uint256 amoutToken)public{
        
        require(msg.sender == owner);
        require(IERC20(token).balanceOf(address(this))> 0);
        
        TransferHelper.safeTransfer(
        token,
        owner,
        amoutToken
        );
         Price[token][pegTokens[token]] =
         IERC20(token).balanceOf(address(this)) * IERC20(pegTokens[token]).balanceOf(address(this));
         
         Price[pegTokens[token]][token] =
         IERC20(token).balanceOf(address(this)) * IERC20(pegTokens[token]).balanceOf(address(this));
         
    }
    
    function swap(address token , uint256 amount)public{
        require(amount >0);
        require(token != address(0));
        require(pair[token][pegTokens[token]] == true);
        
        IERC20(token).transfer(address(this), amount);
        uint256 remain =  Price[token][pegTokens[token]] / IERC20(token).balanceOf(address(this));
        uint256 lastBalanceToken2 = IERC20(pegTokens[token]).balanceOf(address(this));
        uint256 mustTake = lastBalanceToken2 - remain;
        TransferHelper.safeTransfer(
        pegTokens[token],
        msg.sender,
        mustTake 
        );
        Price[token][pegTokens[token]] = 
        IERC20(token).balanceOf(address(this)) * IERC20(pegTokens[token]).balanceOf(address(this));
        
        IERC20(token).transfer(msg.sender, amount);
        
    }
    
}