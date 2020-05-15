pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

//!!!!!!!!!!!!!!!!!!!!!!!!!!!Read me!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//  Functionalities of this contract:
//  Except "sell_to_exchange", other functions are not payable. Assume other transactions are all off-line.
//- acquire: for "AntiqueExchange" Admin to add a new item into the inventory, set it to sell and add ask price
//- buy_from_exchange : for buyer to buy items on sell from the "AntiqueExchange" admin, purchase_price is the 
//                      ask_price set by admin
//- set_item_to_sell_with_asking_price : for owners with Antique item, to set item on sell and add ask price
//- sell_to_exchange : for owners with Antique item and agree with Exchange's price, use this function to sell to the
//                     admin. It should be a payable function. For demostration purpose, the money transfered is pre-defined
//- buy_from_another: for buyer to buy items on sell from other buyers
//- browse_on_sell_items: Returns information of all items on sell
//- show_what_you_have: Returns information of the item caller holds

contract AntiqueExchange {
    enum ItemType {
        NONE,
        WATCH,
        PEN,
        TABLE,
        CHAIR,
        PAINTING,
        MIRROR,
        CARPET
    }
   
    // price for sell to exchange
    // TODO: might need APIs for all these
    uint watch_purchase_price;
    uint pen_purchase_price;
    uint table_purchase_price;
    uint chair_purchase_price;
    uint painting_purchase_price;
    uint mirror_purchase_price;
    uint carpet_purchase_price;
   
   
    address public admin;
    Item[]  private item_list;
    
    // right now, one owner can only own one item
    mapping(address => Item)    private owner_list;

    struct Item {
        address     owner;
        ItemType    item;
        bool        set_to_sell;
        uint        ask_price;
        uint        purchase_price;
    }
    
    address[] private owners;
  
   // set constructor as admin
   constructor() public{
       admin = msg.sender;
   }
   
   // set restriction modifier
   modifier adminonly(){
       require(msg.sender == admin);
       _;
   }
   
   // to avoid duplicates
    function addOwner(address owner) private {
        for (uint i=0; i<owners.length; ++i) {
            if ( owners[i] == owner ) {
                return;                
            }
        }    
        owners.push(owner);
    }
    
     function compareStringsbyBytes(string memory s1, string memory s2) private pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
   
   // get Enum value by key
   function getKeybyValue(string memory value) private pure returns (ItemType){
       if (compareStringsbyBytes(value,"NONE")) return ItemType.NONE;
       if (compareStringsbyBytes(value,"WATCH")) return ItemType.WATCH;
       if (compareStringsbyBytes(value,"PEN")) return ItemType.PEN;
       if (compareStringsbyBytes(value,"TABLE")) return ItemType.TABLE;
       if (compareStringsbyBytes(value,"CHAIR")) return ItemType.CHAIR;
       if (compareStringsbyBytes(value,"PAINTING")) return ItemType.PAINTING;
       if (compareStringsbyBytes(value,"MIRROR")) return ItemType.MIRROR;
       if (compareStringsbyBytes(value,"CARPET")) return ItemType.CARPET;
   }
    
    function acquire(string memory item_type, uint set_ask_price) public adminonly{
        Item storage new_item = owner_list[admin];
        new_item.owner = admin;
        new_item.item = getKeybyValue(item_type);
        new_item.ask_price = set_ask_price;
        new_item.set_to_sell=true;
        item_list.push(new_item);
        addOwner(msg.sender);
    }
    
    function buy_from_exchange(string memory item_type) public {
       
        require(owner_list[admin].item == getKeybyValue(item_type));
        require(owner_list[admin].set_to_sell);
        
        Item storage new_item = owner_list[msg.sender];
        new_item.owner = msg.sender;
        new_item.item = getKeybyValue(item_type);
        new_item.purchase_price = owner_list[admin].ask_price;
        
        owner_list[admin].item=getKeybyValue("NONE");
        owner_list[admin].set_to_sell=false;
        owner_list[admin].ask_price=0;
        owner_list[admin].purchase_price=0;
        item_list.push(new_item);
        addOwner(msg.sender);
    }  
    
    // transfer item_type into uint value
    function get_price(string memory value) private view returns (uint){
        if (compareStringsbyBytes(value,"WATCH")) return watch_purchase_price;
        if (compareStringsbyBytes(value,"PEN")) return pen_purchase_price;
        if (compareStringsbyBytes(value,"TABLE")) return table_purchase_price;
        if (compareStringsbyBytes(value,"CHAIR")) return chair_purchase_price;
        if (compareStringsbyBytes(value,"PAINTING")) return painting_purchase_price;
        if (compareStringsbyBytes(value,"MIRROR")) return mirror_purchase_price;
        if (compareStringsbyBytes(value,"CARPET")) return carpet_purchase_price;
    }
   
    function sell_to_exchange(string memory item_type) payable public {
        // change Item.owner to admin and "transfer" XXXX_purchase_price to sellor(caller)
        require(owner_list[msg.sender].set_to_sell);
        owner_list[msg.sender].item=getKeybyValue("NONE");
        owner_list[msg.sender].set_to_sell=false;
        owner_list[msg.sender].ask_price=0;
        owner_list[msg.sender].purchase_price=0;
        
        msg.sender.transfer(get_price(item_type));
        
        owner_list[admin].item=getKeybyValue("NONE");
        owner_list[admin].item = getKeybyValue(item_type);
        owner_list[admin].purchase_price = get_price(item_type);
        owner_list[admin].ask_price=0;
        owner_list[admin].set_to_sell=false;
    }
   
    function buy_from_another(address another, string memory item_type) public {
        // should 1st check if the item is on_sell. then check the ask_price
        require(owner_list[another].set_to_sell);
        
        Item storage new_item = owner_list[msg.sender];
        new_item.owner = msg.sender;
        new_item.item = getKeybyValue(item_type);
        new_item.purchase_price = owner_list[another].ask_price;
        
        owner_list[another].item=getKeybyValue("NONE");
        owner_list[another].set_to_sell=false;
        owner_list[another].ask_price=0;
        owner_list[another].purchase_price=0;
        item_list.push(new_item);
        addOwner(msg.sender);
    }
   
    function set_item_to_sell_with_asking_price(string memory item_type, uint ask_price) public {
        // only item owner can do
        require(owner_list[msg.sender].item == getKeybyValue(item_type));
        owner_list[msg.sender].set_to_sell = true;
        owner_list[msg.sender].ask_price=ask_price;
    }
   
    function browse_on_sell_items() external view returns (address, ItemType,uint) {
        // show owner, item_type, ask_price
        for (uint i=0; i<owners.length;i++){
            if(owner_list[owners[i]].set_to_sell == true) 
            return (owner_list[owners[i]].owner,
                    owner_list[owners[i]].item,
                    owner_list[owners[i]].ask_price);
        }
    }
    
    function show_what_you_have() public view returns(Item memory){
        return owner_list[msg.sender];
    }
}
