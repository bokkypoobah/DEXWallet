pragma solidity ^0.4.24;

import "Owned.sol";
import "CloneFactory.sol";


// ----------------------------------------------------------------------------
// Membership Data Structure
// ----------------------------------------------------------------------------
library Orders {
    struct Order {
        address fromToken;
        address toToken;
        uint price;
        uint amount;
        uint index;
    }
    struct Data {
        bool initialised;
        mapping(bytes32 => Order) orders;
        bytes32[] index;
    }

    event OrderAdded(bytes32 indexed key, address fromToken, address toToken, uint price, uint amount, uint totalAfter);
    event OrderRemoved(bytes32 indexed key, address fromToken, address toToken, uint price, uint amount, uint totalAfter);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function getKey(address fromToken, address toToken, uint price) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(fromToken, toToken, price));
    }
    function exists(Data storage self, bytes32 key) internal view returns (bool) {
        return self.orders[key].fromToken != address(0);
    }
    function add(Data storage self, address fromToken, address toToken, uint price, uint amount) internal returns (bytes32) {
        bytes32 key = getKey(fromToken, toToken, price);
        require(self.orders[key].fromToken != address(0));
        self.index.push(key);
        self.orders[key] = Order(fromToken, toToken, price, amount, self.index.length - 1);
        emit OrderAdded(key, fromToken, toToken, price, amount, self.index.length);
    }
    function remove(Data storage self, bytes32 key) internal {
        Order memory order = self.orders[key];
        require(order.fromToken != address(0));
        uint removeIndex = order.index;
        emit OrderRemoved(key, order.fromToken, order.toToken, order.price, order.amount, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        bytes32 lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.orders[lastIndexKey].index = removeIndex;
        delete self.orders[key];
        if (self.index.length > 0) {
            self.index.length--;
        }
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}


// ----------------------------------------------------------------------------
// DEXWallet contract
// ----------------------------------------------------------------------------
contract DEXWallet is Owned {
    using Orders for Orders.Data;

    uint public xyz = 123;
    address public owner;
    Orders.Data orders;
    // token => price => approved
    // mapping(address => mapping(uint => uint)) orders;
    bool initialised;

    // Copied from Orders library so it is presented in the ABI
    event OrderAdded(bytes32 indexed key, address fromToken, address toToken, uint price, uint amount, uint totalAfter);
    event OrderRemoved(bytes32 indexed key, address fromToken, address toToken, uint price, uint amount, uint totalAfter);

    function init(address _owner) public {
        require(!initialised);
        initOwned(_owner);
        initialised = true;
    }

    function getOrderKey(address fromToken, address toToken, uint price) public pure returns (bytes32) {
        return Orders.getKey(fromToken, toToken, price);
    }
    function addOrder(address fromToken, address toToken, uint price, uint amount) public returns (bytes32) {
        return orders.add(fromToken, toToken, price, amount);
    }
    function increaseOrder(address fromToken, address toToken, uint price, uint amount) public returns (uint _newAmount) {
        bytes32 key = Orders.getKey(fromToken, toToken, price);
        Orders.Order storage order = orders.orders[key];
        if (order.fromToken != address(0)) {
            order.amount = order.amount + amount;
            _newAmount = order.amount;
        } else {
            orders.add(fromToken, toToken, price, amount);
            _newAmount = amount;
        }
    }
    function decreaseOrder(address fromToken, address toToken, uint price, uint amount) public returns (uint _newAmount) {
        bytes32 key = Orders.getKey(fromToken, toToken, price);
        Orders.Order storage order = orders.orders[key];
        require(order.fromToken != address(0));
        if (amount >= order.amount) {
            orders.remove(key);
            _newAmount = 0;
        } else {
            order.amount = order.amount - amount;
            _newAmount = order.amount;
        }
    }
    function updateOrderPrice(address fromToken, address toToken, uint oldPrice, uint newPrice) public returns (uint _newAmount) {
        bytes32 oldKey = Orders.getKey(fromToken, toToken, oldPrice);
        Orders.Order storage oldOrder = orders.orders[oldKey];
        require(oldOrder.fromToken != address(0));
        bytes32 newKey = Orders.getKey(fromToken, toToken, newPrice);
        Orders.Order storage newOrder = orders.orders[newKey];
        if (newOrder.fromToken != address(0)) {
            newOrder.amount = newOrder.amount + oldOrder.amount;
            _newAmount = newOrder.amount;
        } else {
            orders.add(fromToken, toToken, newPrice, oldOrder.amount);
            _newAmount = oldOrder.amount;
        }
        orders.remove(oldKey);
    }
    function removeOrder(bytes32 key) public {
        orders.remove(key);
    }
    function getOrderByKey(bytes32 key) public view returns (address _fromToken, address _toToken, uint _price, uint _amount) {
        Orders.Order memory order = orders.orders[key];
        return (order.fromToken, order.toToken, order.price, order.amount);
    }
    function getOrderByIndex(uint index) public view returns (address _fromToken, address _toToken, uint _price, uint _amount) {
        bytes32 key = orders.index[index];
        Orders.Order memory order = orders.orders[key];
        return (order.fromToken, order.toToken, order.price, order.amount);
    }
    function getNumberOfOrders() public view returns (uint) {
        return orders.index.length;
    }
    function getOrderKey(uint index) public view returns (bytes32) {
        return orders.index[index];
    }
}


// ----------------------------------------------------------------------------
// DEXWalletFactory contract
// ----------------------------------------------------------------------------
contract DEXWalletFactory is CloneFactory, Owned {
    DEXWallet public walletTemplate;

    DEXWallet[] public wallets;
    mapping(address => address[]) public ownedWallets;

    event WalletCreated(address indexed owner, address indexed dexWalletAddress);

    constructor() public {
        walletTemplate = new DEXWallet();
        initOwned(msg.sender);
    }

    function newDEXWallet() public {
        newDEXWalletFor(msg.sender);
    }
    function newDEXWalletFor(address _owner) public {
        DEXWallet newWallet = DEXWallet(createClone(address(walletTemplate)));
        newWallet.init(_owner);
        wallets.push(newWallet);
        ownedWallets[msg.sender].push(newWallet);
        emit WalletCreated(_owner, address(newWallet));
    }
    function numberOfWallets() public view returns (uint) {
        return wallets.length;
    }
}
