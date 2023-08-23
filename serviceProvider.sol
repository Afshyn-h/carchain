pragma solidity ^0.6.0;

import "./IERC20.sol";

contract service_provider{
    
    event ServiceProviderRegistered(address indexed _serviceProviderAddress, string indexed _name, string);
    event Stake(address indexed serviceProvider, string indexed nameOfServiceProvider, uint amountOfStake,string);
    event serviceProviderRequestForExit(address _serviceProviderAddress, string _name, string);
    event ServiceProviderWithdrawStake(address _serviceProviderAddress, string _name, uint _amount, string);
    event ownerPreventFromExit(address serviceProviderAddress, string _name, string);
    event serviceProviderStakeBlocked(address _serviceProviderAddress, address _treasuryAddress, uint _amount, string);
    
    uint delayTimeForServiceProvider;
    uint exitTimeForServiceProvider;
    address CarNCAddress;
    address owner;
    uint activeServiceProviders;
    uint inactiveServiceProviders;
    address[] allActiveServiceProviders;
    address[] allInactiveServiceProviders;
    IERC20 CarNCToken = IERC20(CarNCAddress);
    
    constructor(address _carchainTokenAddress, uint _delayTimeForServiceProvider, address _owner)public {
        CarNCAddress = _carchainTokenAddress;
        delayTimeForServiceProvider = _delayTimeForServiceProvider;
        owner = _owner;
    }
    
    function changeExitAndDelayTimeForServiceProvider(uint _delay,uint _exit)public  {
        require(msg.sender == owner);
        delayTimeForServiceProvider = _delay;
        exitTimeForServiceProvider = _exit;
    }
    
    struct serviceProvider {
        string name;
        address serviceProviderManagmentAddress;
        address serviceProviderFeeAddress;
        address serviceProviderAddress;
        string restAddress;
        string socketAddress;
        bool deposit;
        uint amountOfDeposit;
        uint startTime;
        uint exitTime;
        bool exit;
        uint8 fee;
    }
    
    mapping (address => address)serviceProviderAddressToManagmentAddress;
    mapping (address => address)serviceProviderManagmentAddressToAddress;
    
    mapping (address => bytes32[])SPL;
    mapping (address => mapping(bytes32 => bool))SPLExist;
    mapping (address => serviceProvider)ServiceProvider;
    mapping (bytes32 => address[])activeSPsInLocation;
    
    mapping (address => mapping(address =>bool)) ExitAcceptanceFromOwner;
    // ExitAcceptanceFromOwner[serviceProviderAddress][_owner]
    mapping (bytes32 => mapping(bytes32 => mapping(bytes32 => address[])))
    AddressOfServiceProvidersByCountryAndProvinceAndCity;
    //AddressOfServiceProvidersBycityAndCountry[_country][_province][_city] = address[]
    mapping (string => address)public GetServiceProviderAddressByName;
    
    
    function setServiceProviderFee(uint8 _fee)public{
        ServiceProvider[msg.sender].fee = _fee;
    }
    
    function stake() public returns(bool){
       require(ServiceProvider[msg.sender].deposit == false);
        CarNCToken.transfer(address(this), 10);
        ExitAcceptanceFromOwner[msg.sender][owner] = true;
        ServiceProvider[msg.sender].amountOfDeposit = 10;
        ServiceProvider[msg.sender].startTime = now;
        ServiceProvider[msg.sender].deposit = true;
        inactiveServiceProviders--;
        activeServiceProviders++;
        allActiveServiceProviders.push(msg.sender);
        emit Stake(msg.sender, ServiceProvider[msg.sender].name, 10, "this service provider actived on Carchain.");
    }
    
    function serviceProviderRegister(string memory _name,
    string memory _restAddress,
    string memory _socketAddress,
    address _serviceProviderFeeAddress,
    address _serviceProviderAddress,
    bytes32[] memory _ID)public {
        require(ServiceProvider[msg.sender].serviceProviderManagmentAddress != msg.sender);
        require(_serviceProviderAddress != msg.sender,
        'service provider address should not be equal to managment address');
        require(_serviceProviderFeeAddress != msg.sender,
        'service provider fee address should not be equal to managment address');
        require(_serviceProviderFeeAddress != _serviceProviderAddress,
        'service provider fee address should not be equal to service provider address');
        
        serviceProviderManagmentAddressToAddress[msg.sender] = _serviceProviderAddress;
        serviceProviderAddressToManagmentAddress[_serviceProviderAddress] = msg.sender ;
        ServiceProvider[msg.sender].serviceProviderManagmentAddress = msg.sender;
        ServiceProvider[msg.sender].serviceProviderFeeAddress = _serviceProviderFeeAddress;
        ServiceProvider[msg.sender].serviceProviderAddress = _serviceProviderAddress;
        ServiceProvider[msg.sender].deposit = false;
        ServiceProvider[msg.sender].name = _name;
        ServiceProvider[msg.sender].restAddress = _restAddress;
        ServiceProvider[msg.sender].socketAddress = _socketAddress;
        GetServiceProviderAddressByName[_name] = _serviceProviderAddress;
        for(uint i=0;i<_ID.length;i++){
            if(SPLExist[_serviceProviderAddress][_ID[i]] == false){
                SPLExist[_serviceProviderAddress][_ID[i]] = true;
                SPL[_serviceProviderAddress].push(_ID[i]);
                activeSPsInLocation[_ID[i]].push(_serviceProviderAddress);
            }
        emit ServiceProviderRegistered(msg.sender, _name,
        "this service provider registered on Carchain but not activeted yet.");
            
        }
    }
    
    function addCityforServiceProvider(bytes32[] memory _ID)public{
        require(ServiceProvider[serviceProviderAddressToManagmentAddress[msg.sender]].serviceProviderAddress ==
        msg.sender);
        
        for(uint i=0; i<_ID.length; i++){
            if(SPLExist[msg.sender][_ID[i]] == false){
                SPLExist[msg.sender][_ID[i]] = true;
                SPL[msg.sender].push(_ID[i]);
            }
        }
    }
    
    function removeCityForServiceProvider(bytes32[] memory _ID)public{
        require(ServiceProvider[serviceProviderAddressToManagmentAddress[msg.sender]].serviceProviderAddress ==
        msg.sender);
        for(uint i=0;i<_ID.length;i++){
            if(SPLExist[msg.sender][_ID[i]] == true){
                SPLExist[msg.sender][_ID[i]] == false;
                
                for(uint k=0;k<SPL[msg.sender].length;k++){  
                    if(SPL[msg.sender][k] == _ID[i]){
                      bytes32 temp=  SPL[msg.sender][SPL[msg.sender].length-1];
                      SPL[msg.sender].pop();
                      SPL[msg.sender][k] = temp;
                      break;
                    }
                }
            }        
        }
    }
    
    
    function getServiceProvidersAddressByID(bytes32 _ID)public view returns(address[] memory){
        
        return(activeSPsInLocation[_ID]);
    }
    
    function getInactiveServiceProviders(address _serviceProviderAddress)public view returns(string memory){
        if(ServiceProvider[_serviceProviderAddress].deposit == false
        && ServiceProvider[_serviceProviderAddress].exit == false){
             return(ServiceProvider[_serviceProviderAddress].name);
        }
    }
    
    function getExitedServiceProviders(address _serviceProviderAddress)public view returns(string memory){
        if(ServiceProvider[_serviceProviderAddress].exit == true){
            return(ServiceProvider[_serviceProviderAddress].name);
        }
    }
    
    function getSocketAndRestAddressOfServiceProvider(address _serviceProviderAddress)
    public view returns(string memory ,uint,string memory,string memory) {
        address managmentAddress = serviceProviderAddressToManagmentAddress[_serviceProviderAddress];
        if(ServiceProvider[managmentAddress].deposit == true 
        && ServiceProvider[managmentAddress].exit == false
        && ServiceProvider[managmentAddress].startTime*1 days >= now*delayTimeForServiceProvider*1 days ){
            return(
        ServiceProvider[managmentAddress].name,
        ServiceProvider[managmentAddress].startTime,
        ServiceProvider[managmentAddress].socketAddress,
        ServiceProvider[managmentAddress].restAddress
        );
        }
    }
    
    function stopExit(address _serviceProviderAddress)public{
        require(msg.sender == owner);
        ExitAcceptanceFromOwner[_serviceProviderAddress][msg.sender] = false;
        emit ownerPreventFromExit(_serviceProviderAddress,
        ServiceProvider[_serviceProviderAddress].name,
        "owner prevent of exit service provider for any reason.");
    }
    
    function getAmountOfServiceProviderStake(address _serviceProviderAddress)public view returns(uint){
        return(ServiceProvider[_serviceProviderAddress].amountOfDeposit);
    }
    
    function blockServiceProviderStake(address _serviceProviderAddress, address _treasuryAddress, uint _amount)public {
         require(msg.sender == owner);
         require(_amount <= ServiceProvider[_serviceProviderAddress].amountOfDeposit);
        require(ExitAcceptanceFromOwner[_serviceProviderAddress][msg.sender] == false);
        ServiceProvider[_serviceProviderAddress].amountOfDeposit = ServiceProvider[_serviceProviderAddress].amountOfDeposit - _amount;
        CarNCToken.transferForServiceProvider(address(this),
        _treasuryAddress,
        _amount);
        emit serviceProviderStakeBlocked(_serviceProviderAddress,
        _treasuryAddress,
        _amount,
        "service Provider stake blocked by owner for any reason");
    }
    
    function exit()public  {
        require(ExitAcceptanceFromOwner[msg.sender][owner] == true);
        ServiceProvider[msg.sender].exitTime = now ;
        emit serviceProviderRequestForExit(msg.sender, ServiceProvider[msg.sender].name, "this service provider request for exit.");
    }
    
    function withdrawServiceProviderStake() public{
        require(ServiceProvider[msg.sender].exitTime*1 days >= now*exitTimeForServiceProvider*1 days
        && ExitAcceptanceFromOwner[msg.sender][owner] == true);
        CarNCToken.transferForServiceProvider(address(this),
        msg.sender,
        ServiceProvider[msg.sender].amountOfDeposit);
        emit ServiceProviderWithdrawStake(msg.sender,
        ServiceProvider[msg.sender].name,
        ServiceProvider[msg.sender].amountOfDeposit,
        "this service provider withdraw their stake and exit from Carchain.");
    }
    
    mapping(address => address)PassengerKYCInServiceProvider;
    function registerPassenger(address _serviceProviderAddress)public returns(bool){
        require(ServiceProvider[_serviceProviderAddress].deposit == true 
        && ServiceProvider[_serviceProviderAddress].exit == false
        && ServiceProvider[_serviceProviderAddress].startTime*1 days >= now*delayTimeForServiceProvider*1 days);
        PassengerKYCInServiceProvider[msg.sender] = _serviceProviderAddress;
        return(true);
    }
    
    function serviceProviderKYCPassenger(address _passengerAddress)public  returns(bool){
        require(PassengerKYCInServiceProvider[_passengerAddress] == msg.sender);
        require(ServiceProvider[msg.sender].deposit == true 
        && ServiceProvider[msg.sender].exit == false
        && ServiceProvider[msg.sender].startTime*1 days >= now*delayTimeForServiceProvider*1 days);
        PassengerKYCInServiceProvider[msg.sender] = _passengerAddress;
        return(true);
        
    }
    
    function findWitchServiceProviderKYCPassenger(address _passengerAddress)public view returns(address, string memory){
        
        return(PassengerKYCInServiceProvider[_passengerAddress],
        ServiceProvider[PassengerKYCInServiceProvider[_passengerAddress]].name);
    }
        
}