pragma solidity ^0.6.0;


interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view  returns (uint256);
    
    function balance(address _owner)external view returns(uint256);

    function transfer(address _recipient, uint256 _amount) external returns (bool success);

    function allowance(address _tokenOwner, address _spender) external view returns (uint256 remaining);

    function approve(address _spender, uint256 _amount) external returns (bool success);
    
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);

    function increaseAllowance(address _spender, uint256 _addedValue) external returns(bool success);
    
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external  returns (bool success);
    
    function mint( uint256 _amount)external returns(bool success);
    
    function burn(uint256 _amount)external  returns(bool success);
    
    function transferForServiceProvider(address _sender, address _recipient, uint _amount)external returns(bool success);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}