pragma solidity ^0.4.24;

import "SafeMath.sol";
import "Owned.sol";
import "ERC20Interface.sol";
import "CloneFactory.sol";


// ----------------------------------------------------------------------------
// Membership Data Structure
// ----------------------------------------------------------------------------
library Orders {
    enum OrderType {
        Buy,
        Sell
    }
    // GNT/ETH = base/quote = 0.00054087
    struct Order {
        OrderType orderType;
        address baseToken;
        address quoteToken;
        uint price; // in number of quoteToken per unit baseToken
        uint expiry;
        uint amount;
        uint index;
    }
    struct Data {
        bool initialised;
        mapping(bytes32 => Order) orders;
        bytes32[] index;
    }

    event OrderAdded(bytes32 indexed key, uint orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount);
    event OrderRemoved(bytes32 indexed key, uint orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function orderKey(OrderType orderType, address baseToken, address quoteToken, uint price, uint expiry) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(orderType, baseToken, quoteToken, price, expiry));
    }
    function exists(Data storage self, bytes32 key) internal view returns (bool) {
        return self.orders[key].baseToken != address(0);
    }
    function add(Data storage self, OrderType orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount) internal returns (bytes32) {
        bytes32 key = orderKey(orderType, baseToken, quoteToken, price, expiry);
        require(self.orders[key].baseToken == address(0));
        self.index.push(key);
        self.orders[key] = Order(orderType, baseToken, quoteToken, price, expiry, amount, self.index.length - 1);
        emit OrderAdded(key, uint(orderType), baseToken, quoteToken, price, expiry, amount);
    }
    function remove(Data storage self, bytes32 key) internal {
        Order memory order = self.orders[key];
        require(order.baseToken != address(0));
        uint removeIndex = order.index;
        uint lastIndex = self.index.length - 1;
        emit OrderRemoved(key, uint(order.orderType), order.baseToken, order.quoteToken, order.price, order.expiry, order.amount);
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
    using SafeMath for uint;
    using Orders for Orders.Data;

    uint public xyz = 123;
    Orders.Data orders;
    // token => price => approved
    // mapping(address => mapping(uint => uint)) orders;
    bool initialised;

    // Copied from Orders library so it is presented in the ABI
    event OrderAdded(bytes32 indexed key, uint orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount);
    event OrderRemoved(bytes32 indexed key, uint orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount);
    event EthersDeposited(address indexed sender, uint ethers, uint balanceAfter);
    event EthersWithdrawn(address indexed to, uint ethers, uint balanceAfter);
    event TokensDeposited(address indexed sender, uint tokens, uint balanceAfter);
    event TokensWithdrawn(address indexed to, uint tokens, uint balanceAfter);

    function init(address _owner) public {
        require(!initialised);
        initOwned(_owner);
        initialised = true;
    }

    function orderKey(Orders.OrderType orderType, address baseToken, address quoteToken, uint price, uint expiry) public pure returns (bytes32) {
        return Orders.orderKey(orderType, baseToken, quoteToken, price, expiry);
    }
    function addOrder(Orders.OrderType orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount) public onlyOwner returns (bytes32) {
        return orders.add(orderType, baseToken, quoteToken, price, amount, expiry);
    }
    function increaseOrderAmount(Orders.OrderType orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount) public onlyOwner returns (uint _newAmount) {
        bytes32 key = Orders.orderKey(orderType, baseToken, quoteToken, price, expiry);
        Orders.Order storage order = orders.orders[key];
        if (order.baseToken != address(0)) {
            order.amount = order.amount.add(amount);
            _newAmount = order.amount;
        } else {
            orders.add(orderType, baseToken, quoteToken, price, expiry, amount);
            _newAmount = amount;
        }
    }
    function decreaseOrderAmount(Orders.OrderType orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount) public onlyOwner returns (uint _newAmount) {
        bytes32 key = Orders.orderKey(orderType, baseToken, quoteToken, price, expiry);
        Orders.Order storage order = orders.orders[key];
        require(order.baseToken != address(0));
        if (amount >= order.amount) {
            orders.remove(key);
            _newAmount = 0;
        } else {
            order.amount = order.amount.sub(amount);
            _newAmount = order.amount;
        }
    }
    function updateOrderPrice(Orders.OrderType orderType, address baseToken, address quoteToken, uint oldPrice, uint expiry, uint newPrice) public onlyOwner returns (uint _newAmount) {
        bytes32 oldKey = Orders.orderKey(orderType, baseToken, quoteToken, oldPrice, expiry);
        Orders.Order storage oldOrder = orders.orders[oldKey];
        require(oldOrder.baseToken != address(0));
        bytes32 newKey = Orders.orderKey(orderType, baseToken, quoteToken, newPrice, expiry);
        Orders.Order storage newOrder = orders.orders[newKey];
        if (newOrder.baseToken != address(0)) {
            newOrder.amount = newOrder.amount.add(oldOrder.amount);
            _newAmount = newOrder.amount;
        } else {
            orders.add(orderType, baseToken, quoteToken, newPrice, expiry, oldOrder.amount);
            _newAmount = oldOrder.amount;
        }
        orders.remove(oldKey);
    }
    function transferOrderAmountToNewPrice(Orders.OrderType orderType, address baseToken, address quoteToken, uint oldPrice, uint expiry, uint newPrice, uint amount) public onlyOwner returns (uint _oldAmount, uint _newAmount) {
        bytes32 oldKey = Orders.orderKey(orderType, baseToken, quoteToken, oldPrice, expiry);
        Orders.Order storage oldOrder = orders.orders[oldKey];
        require(oldOrder.baseToken != address(0));
        bytes32 newKey = Orders.orderKey(orderType, baseToken, quoteToken, newPrice, expiry);
        Orders.Order storage newOrder = orders.orders[newKey];
        if (newOrder.baseToken != address(0)) {
            if (amount >= oldOrder.amount) {
                newOrder.amount = newOrder.amount.add(oldOrder.amount);
                orders.remove(oldKey);
                _oldAmount = 0;
            } else {
                oldOrder.amount = oldOrder.amount.sub(amount);
                newOrder.amount = newOrder.amount.add(amount);
                _oldAmount = oldOrder.amount;
            }
            _newAmount = newOrder.amount;
        } else {
            if (amount >= oldOrder.amount) {
                _newAmount = oldOrder.amount;
                orders.add(orderType, baseToken, quoteToken, newPrice, expiry, oldOrder.amount);
                orders.remove(oldKey);
                _oldAmount = 0;
            } else {
                oldOrder.amount = oldOrder.amount.sub(amount);
                orders.add(orderType, baseToken, quoteToken, newPrice, expiry, amount);
                _oldAmount = oldOrder.amount;
                _newAmount = amount;
            }
        }
    }
    function removeOrder(bytes32 key) public onlyOwner {
        orders.remove(key);
    }
    function getOrderByKey(bytes32 key) public view returns (address _baseToken, address _quoteToken, uint _price, uint _expiry, uint _amount) {
        Orders.Order memory order = orders.orders[key];
        return (order.baseToken, order.quoteToken, order.price, order.expiry, order.amount);
    }
    function getOrderByIndex(uint index) public view returns (address _baseToken, address _quoteToken, uint _price, uint _expiry, uint _amount) {
        bytes32 key = orders.index[index];
        Orders.Order memory order = orders.orders[key];
        return (order.baseToken, order.quoteToken, order.price, order.expiry, order.amount);
    }
    function getNumberOfOrders() public view returns (uint) {
        return orders.index.length;
    }
    function getOrderKeyByIndex(uint index) public view returns (bytes32) {
        return orders.index[index];
    }
    function () public payable {
    	emit EthersDeposited(msg.sender, msg.value, address(this).balance);
    }
    function withdrawEthers(address to, uint ethers) public onlyOwner {
    	to.transfer(ethers);
    	emit EthersWithdrawn(to, ethers, address(this).balance);
    }
    function depositTokens(address tokenAddress, uint tokens) public {
    	ERC20Interface token = ERC20Interface(tokenAddress);
    	uint balanceBefore = token.balanceOf(address(this));
    	require(token.transferFrom(msg.sender, address(this), tokens));
    	uint balanceAfter = token.balanceOf(address(this));
    	require(balanceBefore.add(tokens) == balanceAfter);
    	emit TokensDeposited(msg.sender, tokens, balanceAfter);
    }
    function withdrawTokens(address tokenAddress, address to, uint tokens) public onlyOwner {
    	ERC20Interface token = ERC20Interface(tokenAddress);
    	uint balanceBefore = token.balanceOf(address(this));
    	require(token.transfer(to, tokens));
    	uint balanceAfter = token.balanceOf(address(this));
    	require(balanceBefore.sub(tokens) == balanceAfter);
    	emit TokensWithdrawn(to, tokens, balanceAfter);
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
