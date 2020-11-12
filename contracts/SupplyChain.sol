/*
    This exercise has been updated to use Solidity version 0.6
    Breaking changes from 0.5 to 0.6 can be found here: 
    https://solidity.readthedocs.io/en/v0.6.12/060-breaking-changes.html
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.7.0;

contract SupplyChain {
    /* set owner */
    address owner;

    /* Add a variable called skuCount to track the most recent sku # */
    uint256 skuCount;

    /* Add a line that creates a public mapping that maps the SKU (a number) to an Item.
     Call this mappings items
  */
    mapping(uint256 => Item) public items;

    /* Add a line that creates an enum called State. This should have 4 states
    ForSale
    Sold
    Shipped
    Received
    (declaring them in this order is important for testing)
  */
    enum State {ForSale, Sold, Shipped, Received}
    /* Create a struct named Item.
    Here, add a name, sku, price, state, seller, and buyer
    We've left you to figure out what the appropriate types are,
    if you need help you can ask around :)
    Be sure to add "payable" to addresses that will be handling value transfer
  */
    struct Item {
        string name;
        uint256 sku;
        uint256 price;
        State state;
        address payable seller;
        address payable buyer;
    }
    /* Create 4 events with the same name as each possible State (see above)
    Prefix each event with "Log" for clarity, so the forSale event will be called "LogForSale"
    Each event should accept one argument, the sku */
    // Log when an item is available for sale
    event LogForSale(uint256 sku);
    // Log when an item is sold
    event LogSold(uint256 sku);
    // Log when a sold item is shipped
    event LogShipped(uint256 sku);
    // Log when a shipped ite has been received
    event LogReceived(uint256 sku);

    /* Create a modifer that checks if the msg.sender is the owner of the contract */
    // Check if the sender of the transaction is the contract owner
    modifier checkSender() {
        require(msg.sender == owner);
        _;
    }
    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint256 _price) {
        require(msg.value >= _price);
        _;
    }
    modifier checkValue(uint256 _sku) {
        //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint256 _price = items[_sku].price;
        uint256 amountToRefund = msg.value - _price;
        items[_sku].buyer.transfer(amountToRefund);
    }

    /* For each of the following modifiers, use what you learned about modifiers
   to give them functionality. For example, the forSale modifier should require
   that the item with the given sku has the state ForSale. 
   Note that the uninitialized Item.State is 0, which is also the index of the ForSale value,
   so checking that Item.State == ForSale is not sufficient to check that an Item is for sale.
   Hint: What item properties will be non-zero when an Item has been added?
   
   PS: Uncomment the modifier but keep the name for testing purposes!
   */

    modifier forSale(uint256 sku) {
        // Check that the current item is for sale. The name of the item must be non-zero
        require(
            items[sku].price > 0 && items[sku].state == State.ForSale,
            "Only registered products are for sale"
        );
        _;
    }
    modifier sold(uint256 sku) {
        // Confirm that the item represented with the sku is already sold
        require(items[sku].state == State.Sold, "Item has not been sold");
        _;
    }
    modifier shipped(uint256 sku) {
        // CHeck that the item has been shipped to the buyer
        require(
            items[sku].state == State.Shipped,
            "This item has not been shipped yet"
        );
        _;
    }
    modifier received(uint256 sku) {
        // Confirm that this items have been received by the buyer
        require(
            items[sku].state == State.Received,
            "This item has not yet been received by the buyer"
        );
        _;
    }

    constructor() public {
        /* Here, set the owner as the person who instantiated the contract
       and set your skuCount to 0. */
        // Set the owner of the contract
        owner = msg.sender;
        // Set the sku count to 0
        skuCount = 0;
    }

    function addItem(string memory _name, uint256 _price)
        public
        returns (bool)
    {
        emit LogForSale(skuCount);
        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        });
        skuCount = skuCount + 1;
        return true;
    }

    /* Add a keyword so the function can be paid. This function should transfer money
    to the seller, set the buyer as the person who called this transaction, and set the state
    to Sold. Be careful, this function should use 3 modifiers to check if the item is for sale,
    if the buyer paid enough, and check the value after the function is called to make sure the buyer is
    refunded any excess ether sent. Remember to call the event associated with this function!*/

    function buyItem(uint256 sku)
        public
        payable
        forSale(sku)
        paidEnough(msg.value)
        checkValue(sku)
    {
        // Let's set this item state to sold first
        items[sku].state = State.Sold;
        // Let's set the buyer of the item
        items[sku].buyer = msg.sender;
        // Let's then transfer the amount to the seller
        items[sku].seller.transfer(msg.value);
        // Log this event
        emit LogSold(sku);
    }

    /* Add 2 modifiers to check if the item is sold already, and that the person calling this function
  is the seller. Change the state of the item to shipped. Remember to call the event associated with this function!*/
    function shipItem(uint256 sku)
        public
        sold(sku)
        verifyCaller(items[sku].seller)
    {
        // Set the item's state to shipped
        items[sku].state = State.Shipped;
        // Log this event
        emit LogShipped(sku);
    }

    /* Add 2 modifiers to check if the item is shipped already, and that the person calling this function
  is the buyer. Change the state of the item to received. Remember to call the event associated with this function!*/
    function receiveItem(uint256 sku)
        public
        shipped(sku)
        verifyCaller(items[sku].buyer)
    {
        // Let's set the item as received
        items[sku].state = State.Received;
        // Log this event
        emit LogReceived(sku);
    }

    /* We have these functions completed so we can run tests, just ignore it :) */

    function fetchItem(uint256 _sku)
        public
        view
        returns (
            string memory name,
            uint256 sku,
            uint256 price,
            uint256 state,
            address seller,
            address buyer
        )
    {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint256(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }
}
