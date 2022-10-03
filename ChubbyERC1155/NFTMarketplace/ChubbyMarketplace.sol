// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace1155 is Ownable {
    
    //general sell fee
    uint256 public gSellFee = 20;
    //general buy fee
    uint256 public gBuyFee = 10;
    
    enum orderType {Sell, Buy}

    struct OrderInfo{
        bool status;
        uint256 nftId;
        uint256 cost;    
        orderType typ3;
        address creator;
    }
    
    mapping(uint256 => OrderInfo) private _order;    
    uint256 _perUserOrderLimit = 5;
    mapping(address => uint256) private _userOrderSize;
    
    struct AdminInfo {
        bool oldAdmin;
        bool nowAdmin;
    }
    mapping(address => AdminInfo) private _admins;
    uint256 public adminCounter;

    
    //private user info
    struct PUserInfo {
        bool status;
        uint256 orderLimit;
        uint256 sellFee;
        uint256 buyFee;
    }
    mapping(address => PUserInfo) private _privatelist;
    uint256 public privatelistCounter;

    mapping(address => bool) private _blacklist;
    uint256 public blacklistCounter;

    bool public paused;

    address private _paymentContract;

    IERC1155 private _orderERC1155Token;
    string public collectionName = "ChubbyFive";
    IERC20 private _paymentERC20Token;
    string public paymentType = "CHU";

    constructor(
        address _CContract,
        address _PContract
    ) {
        _paymentContract = _PContract;
        _orderERC1155Token = IERC1155(_CContract);
        _paymentERC20Token = IERC20(_PContract);           
    }

    modifier onlyOwnerorAdmin(){                
        require(owner()== msg.sender || _admins[msg.sender].nowAdmin, "You are not Authorized");            
         _;
    }

    modifier onlyOwnerorAdminorSender(address user_){        
        require(owner()== msg.sender || _admins[msg.sender].nowAdmin || msg.sender == user_ ,"You are not Authorized");
        _;
    }

    modifier blacklistControl(address user_){        
        require(!_blacklist[msg.sender] && !_blacklist[user_], "blacklisted address");
        _;
    }

    modifier issAddress(address user_){
        require(user_ == address(user_) && user_ != address(0x0), "Address type is invalid");
        _;
    }

    modifier issStrEmpty(string memory str_) { 
        require(bytes(str_).length>0, "invalid data"); 
        _;
    }
 
    function postCreateOrder(uint256[] memory _tokenIds, uint256[] memory _costs) external blacklistControl(address(0)){
        require(!paused, "Contract is on paused");
        require(_tokenIds.length == _costs.length, "invalid order");

        if(_privatelist[msg.sender].status){
            require(_userOrderSize[msg.sender] + _tokenIds.length <= _privatelist[msg.sender].orderLimit, "you are exceeding the total order limit");
        }else{
            require(_userOrderSize[msg.sender] + _tokenIds.length <= _perUserOrderLimit, "you are exceeding the total order limit"); 
        }
                
        for (uint256 i; i < _tokenIds.length; i++) {
            require(_orderERC1155Token.balanceOf(msg.sender, _tokenIds[i]) != 0, "you are not owner of the tokens");

            if(_order[_tokenIds[i]].status && _order[_tokenIds[i]].creator == msg.sender){
                _order[_tokenIds[i]].cost = _costs[i];
            }else if(_order[_tokenIds[i]].status && _order[_tokenIds[i]].creator != msg.sender){
                _order[_tokenIds[i]].cost = _costs[i];
                _order[_tokenIds[i]].creator = msg.sender;
                _userOrderSize[msg.sender]++;
            }else{
                _order[_tokenIds[i]] = OrderInfo(true, _tokenIds[i], _costs[i], orderType.Sell, msg.sender);
                _userOrderSize[msg.sender]++;
            }                           
        }        
    }

    function postCreateOrderAuthorized(address[] memory _addresses, uint256[] memory _tokenIds, uint256[] memory _costs) external onlyOwnerorAdmin{        
        require(_tokenIds.length == _costs.length && _addresses.length == _tokenIds.length, "invalid order");                        
        for (uint256 i; i < _tokenIds.length; i++) {
            require(!_blacklist[_addresses[i]], 
            string(abi.encodePacked("No orders can be given for blacklist registered user: ", _addresses[i])));

            if(_order[_tokenIds[i]].status && _order[_tokenIds[i]].creator == _addresses[i]){
                _order[_tokenIds[i]].cost = _costs[i];
            }else if(_order[_tokenIds[i]].status && _order[_tokenIds[i]].creator != _addresses[i]){
                _order[_tokenIds[i]].cost = _costs[i];
                _order[_tokenIds[i]].creator = _addresses[i];
                _userOrderSize[_addresses[i]]++;
            }else{
                _order[_tokenIds[i]] = OrderInfo(true, _tokenIds[i], _costs[i], orderType.Sell, _addresses[i]);
                _userOrderSize[_addresses[i]]++;
            }                           
        }        
    }

    function deleteOrders(uint256[] memory _tokenIds) external blacklistControl(address(0)){
        
        require(!paused, "Contract is on paused");
        for(uint256 i = 0; i < _tokenIds.length; i++){

            require(_orderERC1155Token.balanceOf(msg.sender, _tokenIds[i]) != 0 || _order[_tokenIds[i]].creator == msg.sender, "you are not owner of the tokens");

            if(_order[_tokenIds[i]].status){
                _order[_tokenIds[i]].status = false;
                _userOrderSize[_order[_tokenIds[i]].creator]--;
            }
        }
    }


    function deleteOrdersAuthorized(uint256[] memory _tokenIds) external onlyOwnerorAdmin{
        
        for(uint256 i = 0; i < _tokenIds.length; i++){            
            if(_order[_tokenIds[i]].status){
                _order[_tokenIds[i]].status = false;
                _userOrderSize[_order[_tokenIds[i]].creator]--;
            }
        }
    }

    function getOrdersInfo(uint256 _orderId) external view returns(OrderInfo memory){
        return _order[_orderId];          
    }

    function renounceOwnership() public virtual override onlyOwner {}

    function putPauseStatus() external onlyOwner{
        paused = !paused;
    }

    function putSellFee(uint256 _newSellFee) external onlyOwner{
        gSellFee = _newSellFee;
    }

    function putBuyFee(uint256 _newBuyFee) external onlyOwner{
        gBuyFee = _newBuyFee;
    }

    function postAddAdminlistMember(address _user) external onlyOwner issAddress(_user) blacklistControl(_user) {
        require(!_admins[_user].nowAdmin, "address has admin privileges");        
        _admins[_user].nowAdmin = true;
        adminCounter++;
    }

    function getAdminlistMember(address _user) external onlyOwnerorAdmin view returns(AdminInfo memory){
        return _admins[_user];
    }

    function deleteAdminlistMember(address _user) external onlyOwner issAddress(_user) {
        require(_admins[_user].nowAdmin, "user is not admin");        
        _admins[_user].nowAdmin = false;
        _admins[_user].oldAdmin = true;
        adminCounter--;
    }

    function postAddPrivatelistMember(
        address _user,
        uint256 _orderLimit,
        uint256 _sellFee,
        uint256 _buyFee
    ) external onlyOwnerorAdmin issAddress(_user) blacklistControl(_user) {
         
        require(_user != owner(), "Not possible to add owner");
        require(!_admins[_user].nowAdmin, "Not possible to add admin");       
        require(!_privatelist[_user].status, "Already in privatelist");
        
        _privatelist[_user] = PUserInfo(true, _orderLimit, _sellFee, _buyFee);

        privatelistCounter++;
    }

    function getPrivatelistMember(address _user) external onlyOwnerorAdminorSender(_user) view returns(PUserInfo memory){
        return _privatelist[_user];
    }

    function deletePrivatelistMember(address _user) external onlyOwnerorAdmin issAddress(_user) {        
        require(_privatelist[_user].status, "User is not in privatelist");
        _privatelist[_user].status = false;
        privatelistCounter--;
    }

    function postAddBlacklistMember(address _user) external onlyOwnerorAdmin issAddress(_user) {  
        require(!_blacklist[_user], "User already blacklisted"); 
        require(_user != owner(), "Not possible to add owner");
        if(_admins[_user].nowAdmin){
            require(msg.sender == owner(), "only owner admin has permission to add blacklist");
            _admins[_user].nowAdmin = false;
            _admins[_user].oldAdmin = true;
        }

        _privatelist[_user].status = false;
        _blacklist[_user] = true;
        blacklistCounter++;
    }

    function deleteBlacklistMember(address _user) external onlyOwnerorAdmin issAddress(_user) {
        require(_blacklist[_user], "the address is not on the black list");
        if(_admins[_user].oldAdmin){
            require(msg.sender == owner(), "only owner admin has permission to add blacklist");            
        }        
        _blacklist[_user] = false; 
        blacklistCounter--;
    }

    function postBuyToken(uint256 _orderId, address _user) external blacklistControl(_user) payable {
        require(!paused, "Contract is on pause");
        require(_order[_orderId].status, "Not order are in sell pool");
        require(!_blacklist[_order[_orderId].creator], "Seller registered in blacklist");
        
        uint256 buyFeeMultiplier = _privatelist[msg.sender].status ? _privatelist[msg.sender].buyFee : gBuyFee;
        uint256 sellFeeMultiplier = _privatelist[_order[_orderId].creator].status ? _privatelist[_order[_orderId].creator].sellFee : gSellFee;
        uint256 totalBuyCost = _order[_orderId].cost + _order[_orderId].cost * buyFeeMultiplier / 100;
        uint256 netSalesRevenue = _order[_orderId].cost - _order[_orderId].cost * sellFeeMultiplier / 100;
        
        require( _paymentContract != address(0) ? (_paymentERC20Token.allowance(msg.sender,address(this)) >= totalBuyCost &&
        _paymentERC20Token.balanceOf(msg.sender) >= totalBuyCost ? true : false):
        (msg.value >= totalBuyCost ? true : false), "You do not have enough items to complete the purchase");
       
        if (_paymentContract == address(0)) { 
            (bool success, ) = payable(_order[_orderId].creator).call{value:(netSalesRevenue)}("");
            require(success);            
        } else {
            _paymentERC20Token.transferFrom(msg.sender, address(this), totalBuyCost - netSalesRevenue);
            _paymentERC20Token.transferFrom(msg.sender, _order[_orderId].creator, netSalesRevenue);
        }

        _orderERC1155Token.safeTransferFrom(_order[_orderId].creator, _user, _orderId, 1, "");
        
        _order[_orderId].status = false;
    }
   
    function checkBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBNB() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function checkTokenBalance() external view onlyOwner returns (uint256) {
        return _paymentERC20Token.balanceOf(address(this));
    }

    function checkBNBBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdrawTokens() public onlyOwner {
        _paymentERC20Token.transfer(msg.sender, _paymentERC20Token.balanceOf(address(this)));
    }
}