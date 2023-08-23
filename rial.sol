pragma solidity ^0.7.4;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/access/Ownable.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/access/AccessControl.sol";

// TODO upgradabgitility
contract RialToken is Ownable, AccessControl{
    mapping (address => uint) balance;
    mapping (address =>  Invoice) riderToInvoiceMapping;
    mapping (address =>  address) driverToRiderMapping;
    
    // exchange address is whitelisted for transfering
    address exchangeAddress;
    
    bytes32 public constant EXCHANGE_ROLE = keccak256("EXCHANGE");
    bytes32 public constant SERVICE_PROVIDER_ROLE = keccak256("SP");
    
    struct Invoice{
        address driver;
        uint cost;
    }
    
    // Events
    event Issue(address indexed addr, uint value);
    event Burn(address indexed addr, uint value);
    event Withdraw(address indexed addr, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event NewInvoice(address indexed rider, address indexed driver, uint value);
    
    constructor(address _exchangeAddress, address _spAddress){
        exchangeAddress = _exchangeAddress;
        _setupRole(EXCHANGE_ROLE,_exchangeAddress);
        _setupRole(SERVICE_PROVIDER_ROLE,_spAddress);
    }
    
    /**
     * @dev create an invoice for the rider to allow him paying to the driver.
     * We check caller to be a service provider.
     * @param rider address of the rider willing to pay
     * @param driver address of the driver
     * @param value number of tokens rider allowed to pay to the driver
     */
    function createInvoice(address rider, address driver, uint value) public returns (bool) {
        Invoice memory invoice = Invoice(driver,value);
        
        require(hasRole(SERVICE_PROVIDER_ROLE, msg.sender));
        // we may check for user balance before creating an invoice
        riderToInvoiceMapping[rider] = invoice;
        driverToRiderMapping[driver] = rider;
        emit NewInvoice(rider,driver,value);
        return true;
    }
    
    function getInvoice(address rider) public view returns(address, uint){
        Invoice memory invoice = riderToInvoiceMapping[rider];
        return (invoice.driver,invoice.cost);
    }
    
    function getBalance(address addr) public view returns(uint){
        return balance[addr];
    }
    
    /**
     * @dev Transfer tokens based on invoice. The user can transfer allowed amount of token inside the invoice to the driver.
     * Transfer only limited to destination and value specified previously in invoice.
     */
    function transfer() public{
        address rider = msg.sender;
        address driver;
        uint cost;
        
        (driver, cost) = getInvoice(rider);
        require(driver != address(0));
        require(balance[rider] >= cost);
        balance[rider] = SafeMath.sub(balance[rider],cost);
        balance[driver] = SafeMath.add(balance[driver],cost);
        emit Transfer(rider,driver,cost);
        _endInvoice(rider);
    }
    
    /**
     * @dev Transfer tokens from a user to the exchange (without need to invoice)
     * @param value amount to be transfered.
     */
    function transfertoExchange(uint value) public{
        address user = msg.sender;
        require(balance[user] >= value);
        balance[user] = SafeMath.sub(balance[user],value);
        balance[exchangeAddress] = SafeMath.add(balance[exchangeAddress],value);
        emit Transfer(user,exchangeAddress,value);
    }
    
    /**
     * @dev method to transfer from exchange to a user. caller is checked to have EXCHANGE_ROLE but,
     * may not be same as exchangeAddress, since we allow all users with EXCHANGE_ROLE to spend from exchange account. 
     * @param user address of destination user.
     * @param value amount to be transfered.
     */
    function transferFromExchange(address user, uint value) public{
        require(hasRole(EXCHANGE_ROLE, msg.sender));
        require(balance[exchangeAddress] >= value);
        balance[exchangeAddress] = SafeMath.sub(balance[exchangeAddress],value);
        balance[user] = SafeMath.add(balance[user],value);
        emit Transfer(exchangeAddress,user,value);
    }
    
    /**
     * @dev withdraw some tokens for user.
     * @param value amount to be withdrawn.
     */
    function withdraw(uint value) public{
        require(balance[msg.sender] >= value);
        balance[msg.sender] = SafeMath.sub(balance[msg.sender],value);
        emit Withdraw(msg.sender,value);
    }
    
    /**
     * @dev withdraw all of user's balance.
     * @return amount withdrawn.
     */
    function withdrawAll() public returns(uint){
        uint userBalance = balance[msg.sender];
        require(userBalance > 0);
        balance[msg.sender] = 0;
        emit Withdraw(msg.sender,userBalance);
        return userBalance;
    }
    
    
    /**
     * @dev driver interface for nullifying invoice. Only driver should call this method.
     */
    function endInvoiceByDriver() public returns (bool) {
        address driver = msg.sender;
        address rider = driverToRiderMapping[driver];
        require(rider != address(0));
        driverToRiderMapping[driver] = address(0);
        return _endInvoice(rider);
    } 
    
    
    /**
     * @dev public interface for nullifying invoice.
     * Only user with SERVICE_PROVIDER_ROLE can call this fuction.
     * @param rider address of the rider whose invoice is going to be nullified.
     */
    function endInvoice(address rider) public returns (bool) {
        require(hasRole(SERVICE_PROVIDER_ROLE, msg.sender));
        return _endInvoice(rider);
    }   
    
    /**
     * @dev Nullifies previous invoice by replacing destination with address 0.
     * @param rider address of the rider whose invoice is going to be nullified.
     */
    function _endInvoice(address rider) private returns(bool){
        Invoice memory invoice = Invoice(address(0),0);
        
        // assigning address 0 as driver and receiver
        riderToInvoiceMapping[rider] = invoice;
        return true;
    } 
    /**
     * @dev issues new tokens. Only callable by owner.
     * @param addr address of the user
     * @param value amount of issued tokens
     */
    function issue(address addr,uint value) public onlyOwner{
        balance[addr] = SafeMath.add(balance[addr],value);
        emit Issue(addr,value);
    }
    
    /**
     * @dev Burns balance of user when requested by owner. This function
     * will decrease user balance to 0 and should be called when user has
     * lost the private key or is withdrawing.
     * @param addr address of the user for burning his balance
     * @return balance before burning
     */
    function burn(address addr) public onlyOwner returns (uint){
        uint userBalance = balance[addr];
        
        balance[addr] = 0;
        emit Burn(addr,userBalance);
        return userBalance;
    }
}