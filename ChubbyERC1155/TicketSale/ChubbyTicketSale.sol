// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TicketSale is ERC1155, Ownable {
    
    using Strings for uint256;
    using Strings for uint8;


    bool public paused = true;
    
    bytes5 paymentName = "BUSD";    
    bytes6 baseExtension = ".json";
    bytes12 name = "Ticket Sale";
    
    string baseURI;
    string ticketGoldenPath = "QmNcEAHjpwrfGHJADrFbMZwB62LQQgA58fs8we3ThVnPHe?filename=chubbyTicket_golden";
    string ticketSilverPath = "QmU85ienPbvkHXnXEJdmXqMuyhofXsFm1UUigfo9EJSy1G?filename=chubbyTicket_silver";
    string ticketBronzePath = "QmXtpK46MU641mwXkQF4CNF5WE1uTWNbTgK7ofxJ3mYuZm?filename=chubbyTicket_bronze";
    

    uint8 private ticketIds;
    uint8 public usersWhitelisted;
    uint8 public userBlacklisted;
    uint8 public adminAmount;
    uint8 public ticketAmountPerUser = 1;        
    uint8 public ticketGoldenMaxAmount = 25;
    uint8 public ticketSilverMaxAmount = 75;
    uint8 public ticketBronzeMaxAmount = 125;
    uint8 public ticketGoldenCurrentAmount;
    uint8 public ticketSilverCurrentAmount;
    uint8 public ticketBronzeCurrentAmount;
    uint256 constant ticketGoldenCost = 75000000000000000000 wei;
    uint256 constant ticketSilverCost = 50000000000000000000 wei;
    uint256 constant ticketBronzeCost = 25000000000000000000 wei;
    uint256 public totalPaid;
    
    address[] private admins;
    address[] marketplaces;
    

    
    enum ticketTypes { TicketGolden, TicketSilver, TicketBronze}

    struct Ticket {  
        uint8 id;
        ticketTypes typ3;    
        uint8 amount;
        uint256 cost;                  
        address creator;        
        address holder;        
    }
    mapping(uint256 => Ticket) private tickets;

    struct wl {
        bool wlStatus;
        uint256 wlTicketGoldenCost;
        uint256 wlTicketSilverCost;
        uint256 wlTicketBronzeCost;
        uint8 wlTicketBuyAmount;
    }
    mapping(address => wl) whitelist;

    struct metadaInfo {
        string metadataUri;
        bool updatedStatus;
    }
    mapping(uint8 => metadaInfo) private ticketMetadata;

    struct Admin {
        bool isAdmin;
        uint8 id;
        address user;        
    }        
    mapping(uint8 => Admin) idToAdmin;

    mapping(address => bool) blacklist; 
    mapping(address => uint8) public amountsTicket;
    mapping(address => uint8) public amountsTicketMinted;
    mapping(address => uint8) adrToId;
    mapping(address => bool) isAdmin;
    mapping(address => uint8[]) adrToIds;
    
    

    IERC20 private token20;
    event TicketSaleResponse(string respons3);


    constructor(
        string memory uri_,                                       
        address payingContract_
    ) ERC1155(uri_) {      
        baseURI = uri_;                             
        token20 = IERC20(payingContract_); 
        whitelist[owner()].wlStatus = true;
        whitelist[owner()].wlTicketGoldenCost = 75000000000000000000;
        whitelist[owner()].wlTicketSilverCost = 50000000000000000000;
        whitelist[owner()].wlTicketBronzeCost = 25000000000000000000;
        whitelist[owner()].wlTicketBuyAmount = 5;
        usersWhitelisted++;       
    }

    function buyTickets(address toAddress_, uint8 amount_, ticketTypes tickettype_) external payable {
        require(!paused, "buy ticket is paused");
        require(!blacklist[msg.sender], "you are in blacklist");
        require(!blacklist[toAddress_], "delivery address is in blacklist");        
        require(tickettype_ == ticketTypes.TicketGolden || tickettype_ == ticketTypes.TicketSilver || tickettype_ == ticketTypes.TicketBronze,
         "invalid ticket type");


        if(tickettype_ == ticketTypes.TicketGolden) {
            require(ticketGoldenCurrentAmount + amount_ <= ticketGoldenMaxAmount, "You can't buy more Gold tickets");

            if (whitelist[msg.sender].wlStatus) {
                       
            require(
                amountsTicketMinted[msg.sender] + amount_ <= whitelist[msg.sender].wlTicketBuyAmount,
                "you cannot buy more tickets");
           
            require(token20.balanceOf(msg.sender) >= amount_ * whitelist[msg.sender].wlTicketGoldenCost,
             "You have not enough token balance for purchase!");
             
            token20.transferFrom(
            msg.sender,
            address(this),
            amount_ * whitelist[msg.sender].wlTicketGoldenCost);

             
            totalPaid += amount_ * whitelist[msg.sender].wlTicketGoldenCost;


            } else {
            require(
                amountsTicketMinted[msg.sender] + amount_ <= ticketAmountPerUser,
                "ticket collection amount is exceeded"
            );
            
            token20.transferFrom(
            msg.sender,
            address(this),
            amount_ * ticketGoldenCost);

            totalPaid += amount_ * ticketGoldenCost;

            }

            for (uint8 i; i < amount_; i++) {            
            _mint(toAddress_, ticketIds, 1, "");            
            ticketGoldenCurrentAmount++;            
             if (!isInArray(adrToIds[toAddress_], ticketIds)) {
                adrToIds[toAddress_].push(ticketIds);
            }
            
            tickets[ticketIds] = Ticket(ticketIds, ticketTypes.TicketGolden, 1, ticketGoldenCost, msg.sender, toAddress_);

            amountsTicket[toAddress_]++;

            amountsTicketMinted[msg.sender]++;
            
            ticketIds++;
            
            }
            string memory gMsg = "Congratulations, you have successfully purchased a Golden ticket.";
            emit TicketSaleResponse(gMsg);  

        }else if(tickettype_ == ticketTypes.TicketSilver){

            require(ticketSilverCurrentAmount + amount_ <= ticketSilverMaxAmount, "You can't buy more Silver tickets");

            if (whitelist[msg.sender].wlStatus) {
                       
            require(
                amountsTicketMinted[msg.sender] + amount_ <= whitelist[msg.sender].wlTicketBuyAmount,
                "you cannot buy more tickets");
           
            require(token20.balanceOf(msg.sender) >= amount_ * whitelist[msg.sender].wlTicketSilverCost,
             "You have not enough token balance for purchase!");
             
            token20.transferFrom(
            msg.sender,
            address(this),
            amount_ * whitelist[msg.sender].wlTicketSilverCost);

             
            totalPaid += amount_ * whitelist[msg.sender].wlTicketSilverCost;


            }else {
            require(
                amountsTicketMinted[msg.sender] + amount_ <= ticketAmountPerUser,
                "ticket collection amount is exceeded"
            );
            
            token20.transferFrom(
            msg.sender,
            address(this),
            amount_ * ticketSilverCost);

            totalPaid += amount_ * ticketSilverCost;

            }

            for (uint8 i; i < amount_; i++) {            
            _mint(toAddress_, ticketIds, 1, "");            
            ticketSilverCurrentAmount++;            
             if (!isInArray(adrToIds[toAddress_], ticketIds)) {
                adrToIds[toAddress_].push(ticketIds);
            }
            
            tickets[ticketIds] = Ticket(ticketIds, ticketTypes.TicketSilver, 1, ticketSilverCost, msg.sender, toAddress_);

            amountsTicket[toAddress_]++;

            amountsTicketMinted[msg.sender]++;
            
            ticketIds++;

            }
             string memory sMsg = "Congratulations, you have successfully purchased a Silver ticket.";
            emit TicketSaleResponse(sMsg);  

        }else if(tickettype_ == ticketTypes.TicketBronze){

            require(ticketBronzeCurrentAmount + amount_ <= ticketBronzeMaxAmount, "You can't buy more Bronze tickets");

            if (whitelist[msg.sender].wlStatus) {
                       
            require(
                amountsTicketMinted[msg.sender] + amount_ <= whitelist[msg.sender].wlTicketBuyAmount,
                "you cannot buy more tickets");
           
            require(token20.balanceOf(msg.sender) >= amount_ * whitelist[msg.sender].wlTicketBronzeCost,
             "You have not enough token balance for purchase!");
             
            token20.transferFrom(
            msg.sender,
            address(this),
            amount_ * whitelist[msg.sender].wlTicketBronzeCost);

             
            totalPaid += amount_ * whitelist[msg.sender].wlTicketBronzeCost;


            }else {
            require(
                amountsTicketMinted[msg.sender] + amount_ <= ticketAmountPerUser,
                "ticket collection amount is exceeded"
            );
            
            token20.transferFrom(
            msg.sender,
            address(this),
            amount_ * ticketBronzeCost);

            totalPaid += amount_ * ticketBronzeCost;

            }

            for (uint8 i; i < amount_; i++) {            
            _mint(toAddress_, ticketIds, 1, "");            
            ticketBronzeCurrentAmount++;            
             if (!isInArray(adrToIds[toAddress_], ticketIds)) {
                adrToIds[toAddress_].push(ticketIds);
            }
            
            tickets[ticketIds] = Ticket(ticketIds, ticketTypes.TicketBronze, 1, ticketBronzeCost, msg.sender, toAddress_);

            amountsTicket[toAddress_]++;

            amountsTicketMinted[msg.sender]++;
            
            ticketIds++;
            }  
            
            string memory bMsg = "Congratulations, you have successfully purchased a Bronze ticket.";
            emit TicketSaleResponse(bMsg);          

        }else{
            require(false, "invalid ticket type");
        }                
    }

    function ticketSaleName() external view returns (bytes12) {
        return name;
    }

    function changePauseStatus() external onlyOwner {
        paused = !paused;
    }       

    function _ownerOf(uint256 ticketId_) internal view returns (bool) {
        return balanceOf(msg.sender, ticketId_) != 0;
    }

    function isInArray(uint8[] memory Ids, uint8 id)
        internal
        pure
        returns (bool)
    {
        for (uint8 i; i < Ids.length; i++) {
            if (Ids[i] == id) {
                return true;
            }
        }
        return false;
    }

    function addMarketAdr(address adr) external onlyOwner{
        bool a;
        for(uint i; i < marketplaces.length; i++){
            if(adr == marketplaces[i]){
                a = true;
            }
        }
        if(a == false){
            marketplaces.push(adr);
        }
        
    }

    function checkMarkets() external view returns(address[] memory){
        return marketplaces;
    }

    function deleteMarketAdr(address adr) external onlyOwner {
        for(uint i; i < marketplaces.length; i++){
            if(adr == marketplaces[i]){
                removeMarketAdr(i);
            }
        }
    }

    function removeMarketAdr(uint256 index) internal returns (address[] memory) {
        
        for (uint256 i = index; i < marketplaces.length - 1; i++) {
            marketplaces[i] = marketplaces[i + 1];
        }
        delete marketplaces[marketplaces.length - 1];
        marketplaces.pop();
        return marketplaces;
    }

    function transfer(
        address from_,
        address to_,
        uint8 id_,
        uint8 amount_
    ) external  {
        require(blacklist[msg.sender] == false, "User blacklisted");
        require(!blacklist[to_], "to address User blacklisted");
        require(from_ == msg.sender, "not allowance");
        require(amount_ == 1, "amount has to be 1");
        
        _safeTransferFrom(from_, to_, id_, amount_, "");
        tickets[id_].holder = to_;

        for (uint8 i; i < adrToIds[msg.sender].length; i++) {
            if (adrToIds[msg.sender][i] == id_) {
                adrToIds[to_].push(id_);
                remove(i, msg.sender);
            }
        }
        amountsTicket[msg.sender]--;
        amountsTicket[to_]++;
    }

    function remove(uint8 index_, address user_) internal returns (uint8[] memory) {
        
        for (uint8 i = index_; i < adrToIds[user_].length - 1; i++) {
            adrToIds[user_][i] = adrToIds[user_][i + 1];
        }
        delete adrToIds[user_][adrToIds[user_].length - 1];
        adrToIds[user_].pop();
        return adrToIds[user_];
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {}

    function isInArrayMarket(address[] memory markets, address adr)
        internal
        pure
        returns (bool)
    {
        for (uint8 i; i < markets.length; i++) {
            if (markets[i] == adr) {
                return true;
            }
        }
        return false;
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) public virtual override {
        require(!blacklist[to_], "Buyer is in blacklist");
        require(isInArrayMarket(marketplaces, msg.sender), "This function is only for our marketplace");
        _safeTransferFrom(from_, to_, id_, amount_, data_);
        adrToIds[to_].push(uint8(id_));
        for(uint8 i; i < adrToIds[from_].length; i++){
            if(adrToIds[from_][i] == id_){
                remove(i, from_);
            }
        }
        tickets[id_].holder = to_;
        amountsTicket[from_]--;
        amountsTicket[to_]++;
    }

    function setBaseExtension(bytes6 _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function addToWhitelist(
        address user_,
        uint8 ticketBuyAmount_,
        uint256 ticketGoldenCost_,
        uint256 ticketSilverCost_,
        uint256 ticketBronzeCost_        
    ) external {
        if (isAdmin[user_]) {
            require(
                msg.sender == owner(),
                "only owner can add admin to whitelist"
            );
        } else {
            require(
                msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin,
                "only owner or admin can add to whitelist"
            );
            if (idToAdmin[adrToId[msg.sender]].isAdmin) {
                require(user_ != owner(), "Not possible to add owner");
            }
        }
        
        require(!whitelist[user_].wlStatus, "Already in whitelist");
        
        require(!blacklist[msg.sender], "Admin blacklisted");
        
        whitelist[user_].wlStatus = true;
        whitelist[user_].wlTicketGoldenCost = ticketGoldenCost_;
        whitelist[user_].wlTicketSilverCost = ticketSilverCost_;
        whitelist[user_].wlTicketBronzeCost = ticketBronzeCost_;
        whitelist[user_].wlTicketBuyAmount = ticketBuyAmount_;

        usersWhitelisted++;
        
    }

    function deleteFromWhitelist(address user_) external {
        if (isAdmin[user_]) {
            require(
                msg.sender == owner(),
                "only owner can delete admin from whitelist"
            );
        } else {
            require(
                msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin,
                "only owner or admin can delete from whitelist"
            );
            if (idToAdmin[adrToId[msg.sender]].isAdmin) {
                require(user_ != owner(), "Not possible to add owner");
            }
        }
        require(!blacklist[msg.sender], "Admin blacklisted");

        require(whitelist[user_].wlStatus, "User is not in whitelist");
        delete whitelist[user_];
        usersWhitelisted--;
    }

    function addToBlacklist(address user) external {
        if (isAdmin[user]) {
            require(
                msg.sender == owner(),
                "only owner can add admin to blacklist"
            );
            idToAdmin[adrToId[user]].isAdmin = false;
            for (uint8 i; i < admins.length; i++) {
                if (admins[i] == idToAdmin[adrToId[user]].user) {
                    removeAdmin(i);
                    break;
                }
            }
            adminAmount--;
            isAdmin[user] = false;
        } else {
            require(
                msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin,
                "only owner or admin can add to blacklist"
            );
            if (idToAdmin[adrToId[msg.sender]].isAdmin) {
                require(user != owner(), "Not possible to add owner");
            }
        }
        require(blacklist[msg.sender] == false, "Admin blacklisted");
        require(blacklist[user] == false, "User already blacklisted");
        blacklist[user] = true;
        userBlacklisted++;
    }

    function deleteFromBlacklist(address user) external {
        if (isAdmin[user]) {
            require(
                msg.sender == owner(),
                "only Owner can delete admin from blacklist"
            );
        } else {
            require(
                msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin,
                "only owner or admin can delete from blacklist"
            );
            if (idToAdmin[adrToId[msg.sender]].isAdmin) {
                require(user != owner(), "Not possible to add owner");
            }
        }
        require(blacklist[user] == true, "Admin is not blacklisted");
        require(blacklist[msg.sender] == false, "Admin is not blacklisted");
        blacklist[user] = false;
        userBlacklisted--;
    }

    function addAdmin(address admin) external onlyOwner {
        require(blacklist[msg.sender] == false, "User blacklisted");
        require(isAdmin[admin] != true, "Already admin");
        
        idToAdmin[adminAmount] = Admin(true, adminAmount, admin);
        adrToId[admin] = adminAmount;
        admins.push(admin);
        isAdmin[admin] = true;
        adminAmount++;
    }

    function showAdmins() external view returns (address[] memory) {
        return (admins);
    }

    function deleteAdmin(address admin) external onlyOwner {        
        require(
            idToAdmin[adrToId[admin]].isAdmin == true,
            "User is not in admin list"
        );
        idToAdmin[adrToId[admin]].isAdmin = false;
        for (uint8 i; i < admins.length; i++) {
            if (admins[i] == idToAdmin[adrToId[admin]].user) {
                removeAdmin(i);
                break;
            }
        }
        adminAmount--;
        isAdmin[admin] = false;
    }

    function removeAdmin(uint8 index) internal returns (address[] memory) {
        for (uint8 i = index; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }
        delete admins[admins.length - 1];
        admins.pop();
        return admins;
    }

    function showTickets(uint8 tokenId_) external view returns (Ticket memory) {
        require(tickets[tokenId_].id <= ticketIds);
        return tickets[tokenId_];
    }

    function isUserInBlacklist(address user_) external view returns (bool) {
        require(
            msg.sender == owner() ||
                msg.sender == user_ ||
                idToAdmin[adrToId[msg.sender]].isAdmin
        );

        return blacklist[user_];
    }

    function uri(uint256 ticketId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(ticketGoldenCurrentAmount != 0 || ticketSilverCurrentAmount != 0 || ticketBronzeCurrentAmount != 0, 
        "Non existing ticket id");
        
        require(ticketId_ < ticketIds, "Non existing ticket id");

        string memory ticketUri;

        if (ticketMetadata[uint8(ticketId_)].updatedStatus) {
            return ticketMetadata[uint8(ticketId_)].metadataUri;
        }

        if(tickets[ticketId_].typ3 == ticketTypes.TicketGolden){
           ticketUri = string(abi.encodePacked(baseURI, ticketGoldenPath, baseExtension));
        }else if(tickets[ticketId_].typ3 == ticketTypes.TicketSilver){
           ticketUri = string(abi.encodePacked(baseURI, ticketSilverPath, baseExtension));
        }else if(tickets[ticketId_].typ3 == ticketTypes.TicketBronze){
           ticketUri = string(abi.encodePacked(baseURI, ticketBronzePath, baseExtension));
        }else{
           ticketUri = "";
        }
        
         return ticketUri;
        
    }
    
    function isUserInWhitelist(address user_)
        external
        view
        returns (
            bool,
            uint8,
            uint256,
            uint256,
            uint256
        )
    {
        require(
            msg.sender == owner() ||
                msg.sender == user_ ||
                idToAdmin[adrToId[msg.sender]].isAdmin
        );
     
        require(whitelist[user_].wlStatus, "User is not whilelisted");
        
        return (
            whitelist[user_].wlStatus,
            whitelist[user_].wlTicketBuyAmount,
            whitelist[user_].wlTicketGoldenCost,
            whitelist[user_].wlTicketSilverCost,
            whitelist[user_].wlTicketBronzeCost            
        );
    }




    function availableTickets(address infoAddress_)
        external
        view
        returns (            
            uint8,
            uint256,
            uint256,
            uint256
        )
    {
        if (whitelist[infoAddress_].wlStatus) {
            return (
                whitelist[infoAddress_].wlTicketBuyAmount - amountsTicketMinted[infoAddress_],
                whitelist[infoAddress_].wlTicketGoldenCost,
                whitelist[infoAddress_].wlTicketSilverCost,
                whitelist[infoAddress_].wlTicketBronzeCost                
            );
        } else {
            return (
                ticketAmountPerUser - amountsTicketMinted[infoAddress_],
                ticketGoldenCost,
                ticketSilverCost,
                ticketBronzeCost
            );
        }       
    }

    function withdrawToken() public onlyOwner returns (uint256) {
        uint256 withdrawable = token20.balanceOf(address(this));
        require(withdrawable > 0, "withdraw: Nothing to withdraw");
        require(token20.transfer(
                owner(),
                token20.balanceOf(address(this))
            ), "Withdraw: Can't withdraw!");
        return withdrawable;
    }

    function checkUserTicketIds(address infoUserTicket_) external view returns (uint8[] memory) {
        return adrToIds[infoUserTicket_];
    }

    function changeTicketMetaUri(uint8 ticketId_, string memory newMetaUri_) external {

        require( msg.sender == owner() || idToAdmin[adrToId[msg.sender]].isAdmin );

        require(ticketId_ < ticketIds, "Non existing ticket id");
        ticketMetadata[ticketId_].metadataUri = newMetaUri_;
        ticketMetadata[ticketId_].updatedStatus = true;
    }

    function changeTicketUri(
        string memory newBaseUri_, 
        string memory newGoldenTicketPath_, 
        string memory newSilverTicketPath_, 
        string memory newBronzeTicketPath_) external onlyOwner {
        baseURI = newBaseUri_;
        ticketGoldenPath = newGoldenTicketPath_;
        ticketSilverPath = newSilverTicketPath_;
        ticketBronzePath = newBronzeTicketPath_;
    }
}