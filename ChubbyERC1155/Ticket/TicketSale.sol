// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TicketSale is ERC1155, Ownable {
    
    using Strings for uint256;

    string name = "Closed Beta Ticket Sale";
    string assetContractName;
    IERC20 private token20;

    string baseURI;
    string ticketGoldPath;
    string ticketSilverPath;
    string ticketBronzePath;
    
    string public baseExtension = ".json";
    bool public paused;

    
    uint256 constant ticketGoldCost = 75000000000000000000 wei;
    uint256 constant ticketSilverCost = 50000000000000000000 wei;
    uint256 constant ticketBronzeCost = 25000000000000000000 wei;

    uint256 public totalPaid;

    uint256 private ticketIds;

    mapping(address => uint256[]) adrToIds;

    


    enum ticketTypes { TicketGold, TicketSilver, TicketBronze}

    struct Ticket {  
        uint256 id;
        ticketTypes typ3;    
        uint8 amount;
        uint256 cost;                  
        address creator;        
        address holder;        
    }
    
    mapping(uint256 => Ticket) private tickets;
    


    uint256 public usersWhitelisted;
    uint256 public userBlacklisted;

    address[] marketplaces;

    struct wl {
        bool wlStatus;
        uint256 wlTicketGoldCost;
        uint256 wlTicketSilverCost;
        uint256 wlTicketBronzeCost;
        uint256 wlTicketBuyAmount;
    }

    mapping(address => bool) blacklist;
    mapping(address => wl) whitelist;
    
    mapping(address => uint256) public amountsTicket;
    mapping(address => uint256) public amountsTicketMinted;

    
    mapping(uint256 => Admin) idToAdmin;
    mapping(address => uint256) adrToId;
    mapping(address => bool) isAdmin;
    uint256 public adminAmount;
    address[] private admins;

    struct Admin {
        uint256 id;
        address user;
        bool isAdmin;
    }
    
    uint256 public ticketAmountPerUser;    
    
    uint256 public ticketGoldMaxAmount = 13;
    uint256 public ticketSilverMaxAmount = 13;
    uint256 public ticketBronzeMaxAmount = 13;

    uint256 public ticketGoldCurrentAmount;
    uint256 public ticketSilverCurrentAmount;
    uint256 public ticketBronzeCurrentAmount;

    constructor(
        string memory uri_,
        string memory ticketGoldPath_,
        string memory ticketSilverPath_,
        string memory ticketBronzePath_,                
        uint256 ticketAmountPerUser_, 
        string memory assetName_,       
        address payingContract_
    ) ERC1155(uri_) {       
        baseURI = uri_;
        ticketGoldPath = ticketGoldPath_;
        ticketSilverPath = ticketSilverPath_;
        ticketBronzePath = ticketBronzePath_;
        paused = true;
        ticketAmountPerUser = ticketAmountPerUser_;
        assetContractName = assetName_;        
        token20 = IERC20(payingContract_);        
    }

    function buyTickets(uint256 amount_, ticketTypes tickettype_) external payable {
        require(!paused, "buy ticket is paused");
        require(blacklist[msg.sender] == false, "you are in blacklist");
        require(tickettype_ == ticketTypes.TicketGold || tickettype_ == ticketTypes.TicketSilver || tickettype_ == ticketTypes.TicketBronze,
         "invalid ticket type");

        if(tickettype_ == ticketTypes.TicketGold) {
            require(ticketGoldCurrentAmount + amount_ <= ticketGoldMaxAmount, "You can't buy more gold tickets");

            if (whitelist[msg.sender].wlStatus) {
                       
            require(
                amountsTicketMinted[msg.sender] + amount_ <= whitelist[msg.sender].wlTicketBuyAmount,
                "you cannot buy more tickets");
           
            require(token20.balanceOf(msg.sender) >= amount_ * whitelist[msg.sender].wlTicketGoldCost,
             "You have not enough token balance for purchase!");
             
            token20.transferFrom(
            msg.sender,
            address(this),
            amount_ * whitelist[msg.sender].wlTicketGoldCost);

             
            totalPaid += amount_ * whitelist[msg.sender].wlTicketGoldCost;


            } else {
            require(
                amountsTicketMinted[msg.sender] + amount_ <= ticketAmountPerUser,
                "ticket collection amount is exceeded"
            );
            
            token20.transferFrom(
            msg.sender,
            address(this),
            amount_ * ticketGoldCost);

            totalPaid += amount_ * ticketGoldCost;

            }

            for (uint256 i; i < amount_; i++) {            
            _mint(msg.sender, ticketIds, 1, "");            
            ticketGoldCurrentAmount++;            
             if (!isInArray(adrToIds[msg.sender], ticketIds)) {
                adrToIds[msg.sender].push(ticketIds);
            }
            
            tickets[ticketIds] = Ticket(ticketIds, ticketTypes.TicketGold, 1, ticketGoldCost, msg.sender, msg.sender);

            amountsTicket[msg.sender]++;

            amountsTicketMinted[msg.sender]++;
            
            ticketIds++;
            }
        }else if(tickettype_ == ticketTypes.TicketSilver){

            require(ticketSilverCurrentAmount + amount_ <= ticketSilverMaxAmount, "You can't buy more gold tickets");

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

            for (uint256 i; i < amount_; i++) {            
            _mint(msg.sender, ticketIds, 1, "");            
            ticketSilverCurrentAmount++;            
             if (!isInArray(adrToIds[msg.sender], ticketIds)) {
                adrToIds[msg.sender].push(ticketIds);
            }
            
            tickets[ticketIds] = Ticket(ticketIds, ticketTypes.TicketSilver, 1, ticketSilverCost, msg.sender, msg.sender);

            amountsTicket[msg.sender]++;

            amountsTicketMinted[msg.sender]++;
            
            ticketIds++;
            }

        }else if(tickettype_ == ticketTypes.TicketBronze){

            require(ticketBronzeCurrentAmount + amount_ <= ticketBronzeMaxAmount, "You can't buy more gold tickets");

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

            for (uint256 i; i < amount_; i++) {            
            _mint(msg.sender, ticketIds, 1, "");            
            ticketBronzeCurrentAmount++;            
             if (!isInArray(adrToIds[msg.sender], ticketIds)) {
                adrToIds[msg.sender].push(ticketIds);
            }
            
            tickets[ticketIds] = Ticket(ticketIds, ticketTypes.TicketBronze, 1, ticketBronzeCost, msg.sender, msg.sender);

            amountsTicket[msg.sender]++;

            amountsTicketMinted[msg.sender]++;
            
            ticketIds++;
            }

        }else{
            require(false, "invalid ticket type");
        }                
    }

    function ticketSaleName() external view returns (string memory) {
        return name;
    }

    function changePauseStatus() external onlyOwner {
        paused = !paused;
    }

    function checkUserBuyTicketAmount(address infoAddress_) external view returns (uint256) {
        return amountsTicketMinted[infoAddress_];
    }

    function checkUserActualAmount() external view returns (uint256) {
        return amountsTicket[msg.sender];
    }

    function _ownerOf(uint256 ticketId_) internal view returns (bool) {
        return balanceOf(msg.sender, ticketId_) != 0;
    }

    function isInArray(uint256[] memory Ids, uint256 id)
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < Ids.length; i++) {
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
        uint256 id_,
        uint256 amount_
    ) external  {
        require(blacklist[msg.sender] == false, "User blacklisted");
        require(from_ == msg.sender, "not allowance");
        require(amount_ == 1, "amount has to be 1");
        
        _safeTransferFrom(from_, to_, id_, amount_, "");
        tickets[id_].holder = to_;

        for (uint256 i; i < adrToIds[msg.sender].length; i++) {
            if (adrToIds[msg.sender][i] == id_) {
                adrToIds[to_].push(id_);
                remove(i, msg.sender);
            }
        }
        amountsTicket[msg.sender]--;
        amountsTicket[to_]++;
    }

    function remove(uint256 index_, address user_) internal returns (uint256[] memory) {
        
        for (uint256 i = index_; i < adrToIds[user_].length - 1; i++) {
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
        for (uint256 i; i < markets.length; i++) {
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
        adrToIds[to_].push(id_);
        for(uint i; i < adrToIds[from_].length; i++){
            if(adrToIds[from_][i] == id_){
                remove(i, from_);
            }
        }
        tickets[id_].holder = to_;
        amountsTicket[from_]--;
        amountsTicket[to_]++;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function addToWhitelist(
        address user_,
        uint256 ticketBuyAmount_,
        uint256 ticketGoldCost_,
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

        usersWhitelisted++;
        
        whitelist[user_].wlStatus = true;
        whitelist[user_].wlTicketGoldCost = ticketGoldCost_;
        whitelist[user_].wlTicketSilverCost = ticketSilverCost_;
        whitelist[user_].wlTicketBronzeCost = ticketBronzeCost_;
        whitelist[user_].wlTicketBuyAmount = ticketBuyAmount_;
        
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
        require(blacklist[msg.sender] == false, "Admin blacklisted");

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
            for (uint256 i; i < admins.length; i++) {
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
        adminAmount++;
        idToAdmin[adminAmount] = Admin(adminAmount, admin, true);
        adrToId[admin] = adminAmount;
        admins.push(admin);
        isAdmin[admin] = true;
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
        for (uint256 i; i < admins.length; i++) {
            if (admins[i] == idToAdmin[adrToId[admin]].user) {
                removeAdmin(i);
                break;
            }
        }
        adminAmount--;
        isAdmin[admin] = false;
    }

    function removeAdmin(uint256 index) internal returns (address[] memory) {
        for (uint256 i = index; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }
        delete admins[admins.length - 1];
        admins.pop();
        return admins;
    }

    function showTickets(uint256 tokenId_) external view returns (Ticket memory) {
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
        require(ticketGoldCurrentAmount != 0 || ticketSilverCurrentAmount != 0 || ticketBronzeCurrentAmount != 0, 
        "There is no ticket with the specified id");       
        string memory ticketUrl;

        
        if(tickets[ticketId_].typ3 == ticketTypes.TicketGold){
           ticketUrl = string(abi.encodePacked(baseURI,ticketGoldPath, baseExtension));
        }else if(tickets[ticketId_].typ3 == ticketTypes.TicketSilver){
           ticketUrl = string(abi.encodePacked(baseURI, ticketSilverPath, baseExtension));
        }else if(tickets[ticketId_].typ3 == ticketTypes.TicketBronze){
           ticketUrl = string(abi.encodePacked(baseURI, ticketBronzePath, baseExtension));
        }else{
           ticketUrl = "";
        }

         return ticketUrl;
        
    }
    
    function isUserInWhitelist(address user_)
        external
        view
        returns (
            bool,
            uint256,
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
            whitelist[user_].wlTicketGoldCost,
            whitelist[user_].wlTicketSilverCost,
            whitelist[user_].wlTicketBronzeCost,
            whitelist[user_].wlTicketBuyAmount
        );
    }

    function availableTickets(address infoAddress_)
        external
        view
        returns (            
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (whitelist[infoAddress_].wlStatus) {
            return (
                whitelist[infoAddress_].wlTicketBuyAmount - amountsTicketMinted[infoAddress_],
                whitelist[infoAddress_].wlTicketGoldCost,
                whitelist[infoAddress_].wlTicketSilverCost,
                whitelist[infoAddress_].wlTicketBronzeCost                
            );
        } else {
            return (
                ticketAmountPerUser - amountsTicketMinted[infoAddress_],
                ticketGoldCost,
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
}