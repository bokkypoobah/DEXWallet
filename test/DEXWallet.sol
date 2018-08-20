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
    function exists(Data storage self, bytes32 key) internal view returns (bool) {
        return self.orders[key].fromToken != address(0);
    }
    function add(Data storage self, address fromToken, address toToken, uint price, uint amount) internal returns (bytes32) {
        bytes32 key = keccak256(abi.encodePacked(fromToken, toToken, price, amount));
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
    uint public xyz = 123;
    address public owner;
    // token => price => approved
    mapping(address => mapping(uint => uint)) orders;
    bool initialised;

    function init(address _owner) public {
        require(!initialised);
        initOwned(_owner);
        initialised = true;
    }

    function addOrder(address token, uint price, uint amount) public {
        orders[token][price] = amount;
    }
    function updateOrderAmount(address token, uint price, uint newAmount) public {
        orders[token][price] = newAmount;
    }
    function updateOrderPrice(address token, uint oldPrice, uint newPrice) public {
        uint amount = orders[token][oldPrice];
        orders[token][oldPrice] = 0;
        orders[token][newPrice] = amount;
    }
    function getOrder(address token, uint price) public view returns (uint) {
        return orders[token][price];
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
