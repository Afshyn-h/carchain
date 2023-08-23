pragma solidity ^0.5.10;

import "./IERC20.sol";
import "./safeMath.sol";

contract Carchain_token is IERC20  {
    
    using SafeMath for uint256;
    
    event MintToken(address indexe,uint);
    event Transfer(address indexed _from,address indexed _to,uint _amount);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address,uint);
    
    string constant Name="CarchainNetworkCurrency";
    string constant Symbol="CarNC";
    uint constant Decimals=6;
    uint constant initialSuply=0;
    uint TotalSupply= initialSuply*10**Decimals;
    address ownerOfTotalSupply;
    
    address serviceProviderContractAddress;
    
    function setServiceProviderContractAddress(address _serviceProviderContractAddress)public returns(bool success){
        require(msg.sender == ownerOfTotalSupply);
        serviceProviderContractAddress = _serviceProviderContractAddress;
        return true;
    }
    
    constructor(address _ownerOfTotalSupply)public{
        ownerOfTotalSupply = _ownerOfTotalSupply;
        balanceOf[_ownerOfTotalSupply] = TotalSupply;
    }
    
    mapping(address=>uint)balanceOf;
    mapping(address=>mapping(address=>uint))Allowed;
    
    function balance(address _owner)public view returns(uint256){
        return(balanceOf[_owner]);
    }
    
    function totalSupply()public view returns(uint256) {
        return TotalSupply;
    }
    
    function name()public view returns(string memory){
        return Name;
    }
    
    function symbol()public view returns(string memory){
        return Symbol;
    }
    
    function decimals()public view returns(uint256){
        return Decimals;
    }
    
     function _transfer(address _sender, address _recipient, uint _amount) internal  {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        balanceOf[_sender] = balanceOf[_sender].sub(_amount, "ERC20: transfer amount exceeds balance");
        balanceOf[_recipient] = balanceOf[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }
    
    function transfer(address _recipient,uint _amount)public returns(bool success){
       _transfer(msg.sender, _recipient, _amount);
        return success;
    }
    
     function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        Allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    
    function approve(address _spender,uint _amount)public returns(bool success){
        _approve(msg.sender, _spender, _amount);
        return success;
    }
   
    function allowance(address _tokenOwner, address _spender)public view returns (uint256 remaining) {
        return Allowed[_tokenOwner][_spender];
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public  returns (bool success) {
        _approve(msg.sender, _spender, Allowed[msg.sender][_spender].add(_addedValue));
        return success;
    }
    
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public  returns (bool success) {
        _approve(msg.sender, _spender, Allowed[msg.sender][_spender].sub(_subtractedValue, "ERC20: decreased allowance below zero"));
        return success;
    }
    
    function transferFrom(address _sender,address _recipient,uint _amount)public returns(bool){
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, Allowed[_sender][msg.sender].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
        
   function mint( uint256 _amount) public returns(bool success){
        require( msg.sender == ownerOfTotalSupply);

        TotalSupply = TotalSupply.add(_amount);
        balanceOf[ownerOfTotalSupply] = balanceOf[ownerOfTotalSupply].add(_amount);
        emit Transfer(address(0), ownerOfTotalSupply, _amount);
        emit MintToken(ownerOfTotalSupply, _amount);
        return true;
    }
    
    function burn(uint256 _amount)public returns(bool success){
        require( msg.sender == ownerOfTotalSupply);
        TotalSupply = TotalSupply.sub(_amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount, "ERC20: burn amount exceeds balance");
        emit Transfer(msg.sender, address(0), _amount);
        emit Burn(ownerOfTotalSupply, _amount);
        return true;
    }
    
    function transferForServiceProvider(address _sender, address _recipient, uint _amount)public returns(bool success){
        require(_sender == serviceProviderContractAddress);
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        balanceOf[_sender] = balanceOf[_sender].sub(_amount, "ERC20: transfer amount exceeds balance");
        balanceOf[_recipient] = balanceOf[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
         return true;
    }
    
}