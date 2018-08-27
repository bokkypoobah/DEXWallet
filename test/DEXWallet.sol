pragma solidity ^0.4.24;

import "SafeMath.sol";
import "Owned.sol";
import "ERC20.sol";
import "CloneFactory.sol";


// ----------------------------------------------------------------------------
// Membership Data Structure
// ----------------------------------------------------------------------------
library Orders {
    enum OrderType {
        BUY,
        SELL
    }
    // 0.00054087 = new BigNumber(54087).shift(10);
    // GNT/ETH = base/quote = 0.00054087
    struct Order {
        OrderType orderType;
        address baseToken;      // GNT
        address quoteToken;     // ETH
        uint price;             // GNT/ETH = 0.00054087 = #quoteToken per unit baseToken
        uint expiry;
        uint amount;            // GNT - baseToken
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

    DEXWalletFactory public dexWalletFactory;
    mapping(address => bool) public dexWalletExchangers;
    uint constant public ONEE18 = uint(10)**18;
    Orders.Data orders;
    bool initialised;

    // Copied from Orders library so it is presented in the ABI
    event OrderAdded(bytes32 indexed key, uint orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount);
    event OrderRemoved(bytes32 indexed key, uint orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount);

    event EthersDeposited(address indexed sender, uint ethers, uint balanceAfter);
    event EthersWithdrawn(address indexed to, uint ethers, uint balanceAfter);
    event TokensDeposited(address indexed sender, uint tokens, uint balanceAfter);
    event TokensWithdrawn(address indexed to, uint tokens, uint balanceAfter);
    event LogUint(string note, uint number);
    event TakerSold(bytes32 key, uint amount, address taker, address maker, address baseToken, address quoteToken, uint baseTokens, uint quoteTokens);
    event TakerBought(bytes32 key, uint amount, address taker, address maker, address baseToken, address quoteToken, uint baseTokens, uint quoteTokens);

    modifier onlyDEXWalletExchanger {
        require(dexWalletExchangers[msg.sender] == true && dexWalletFactory.dexWalletExchangers(msg.sender) == true);
        _;
    }

    function init(address _dexWalletFactory, address _owner, address dexWalletExchanger) public {
        require(!initialised);
        dexWalletFactory = DEXWalletFactory(_dexWalletFactory);
        initOwned(_owner);
        dexWalletExchangers[dexWalletExchanger] = true;
        initialised = true;
    }

    function setDEXWalletExchanger(address dexWalletExchanger, bool status) public onlyOwner {
        dexWalletExchangers[dexWalletExchanger] = status;
    }
    function permissionCurrentDEXWalletExchanger() public onlyOwner {
        require(dexWalletExchangers[dexWalletFactory.currentDEXWalletExchanger()] == false);
        dexWalletExchangers[dexWalletFactory.currentDEXWalletExchanger()] = true;
    }

    function () public payable {
    	emit EthersDeposited(msg.sender, msg.value, address(this).balance);
    }
    function withdrawEthers(address to, uint ethers) public onlyOwner {
    	to.transfer(ethers);
    	emit EthersWithdrawn(to, ethers, address(this).balance);
    }
    function depositTokens(address tokenAddress, uint tokens) public {
    	ERC20 token = ERC20(tokenAddress);
    	uint balanceBefore = token.balanceOf(address(this));
    	require(token.transferFrom(msg.sender, address(this), tokens));
    	uint balanceAfter = token.balanceOf(address(this));
    	require(balanceBefore.add(tokens) == balanceAfter);
    	emit TokensDeposited(msg.sender, tokens, balanceAfter);
    }
    function withdrawTokens(address tokenAddress, address to, uint tokens) public onlyOwner {
    	ERC20 token = ERC20(tokenAddress);
    	uint balanceBefore = token.balanceOf(address(this));
    	require(token.transfer(to, tokens));
    	uint balanceAfter = token.balanceOf(address(this));
    	require(balanceBefore.sub(tokens) == balanceAfter);
    	emit TokensWithdrawn(to, tokens, balanceAfter);
    }

    function orderKey(Orders.OrderType orderType, address baseToken, address quoteToken, uint price, uint expiry) public pure returns (bytes32) {
        return Orders.orderKey(orderType, baseToken, quoteToken, price, expiry);
    }
    function addOrder(Orders.OrderType orderType, address baseToken, address quoteToken, uint price, uint expiry, uint amount) public onlyOwner returns (bytes32) {
        return orders.add(orderType, baseToken, quoteToken, price, expiry, amount);
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
    function updateOrderExpiry(Orders.OrderType orderType, address baseToken, address quoteToken, uint price, uint oldExpiry, uint newExpiry) public onlyOwner returns (uint _newAmount) {
        bytes32 oldKey = Orders.orderKey(orderType, baseToken, quoteToken, price, oldExpiry);
        Orders.Order storage oldOrder = orders.orders[oldKey];
        require(oldOrder.baseToken != address(0));
        bytes32 newKey = Orders.orderKey(orderType, baseToken, quoteToken, price, newExpiry);
        Orders.Order storage newOrder = orders.orders[newKey];
        if (newOrder.baseToken != address(0)) {
            newOrder.amount = newOrder.amount.add(oldOrder.amount);
            _newAmount = newOrder.amount;
        } else {
            orders.add(orderType, baseToken, quoteToken, price, newExpiry, oldOrder.amount);
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
    function getOrderByKey(bytes32 key) public view returns (bytes32 _key, uint _orderType, address _baseToken, address _quoteToken, uint _price, uint _expiry, uint _amount) {
        Orders.Order memory order = orders.orders[key];
        return (key, uint(order.orderType), order.baseToken, order.quoteToken, order.price, order.expiry, order.amount);
    }
    function getOrderByIndex(uint index) public view returns (bytes32 _key, uint _orderType, address _baseToken, address _quoteToken, uint _price, uint _expiry, uint _amount) {
        bytes32 key = orders.index[index];
        Orders.Order memory order = orders.orders[key];
        return (key, uint(order.orderType), order.baseToken, order.quoteToken, order.price, order.expiry, order.amount);
    }
    function getNumberOfOrders() public view returns (uint) {
        return orders.index.length;
    }
    function getOrderKeyByIndex(uint index) public view returns (bytes32) {
        return orders.index[index];
    }

    function getEffectiveOrder(bytes32 key) public view returns (uint _orderType, address _baseToken, address _quoteToken, uint _price, uint _expiry, uint _baseAmount, uint _quoteAmount) {
        Orders.Order memory order = orders.orders[key];
        (_orderType, _baseToken, _quoteToken, _price, _expiry) = (uint(order.orderType), order.baseToken, order.quoteToken, order.price, order.expiry);
        if (now <= order.expiry) {
            if (order.orderType == Orders.OrderType.BUY) {
                _baseAmount = order.amount;
                _quoteAmount = _baseAmount.mul(_price).div(ONEE18).min(ERC20(_quoteToken).balanceOf(address(this)));
                _baseAmount = _quoteAmount.mul(ONEE18).div(_price);
            } else {
                _baseAmount = order.amount.min(ERC20(_baseToken).balanceOf(address(this)));
                _quoteAmount = _baseAmount.mul(_price).div(ONEE18);
            }
        }
    }
    function takerSell(bytes32 key, uint amountBaseToken) public returns (uint _baseTokens, uint _quoteTokens) {
        // BK TODO: Iterate of more than one order
        // BK TODO: Handle shrapnel

        Orders.Order memory order = orders.orders[key];
        require(now <= order.expiry);
        require(order.orderType == Orders.OrderType.BUY);

        // emit LogUint("order.amount", order.amount);
        // emit LogUint("amountBaseToken", amountBaseToken);
        // emit LogUint("baseToken.allowance(msg.sender, this)", ERC20(order.baseToken).allowance(msg.sender, address(this)));
        // emit LogUint("baseToken.balanceOf(msg.sender)", ERC20(order.baseToken).balanceOf(msg.sender));
        _baseTokens = order.amount.min(amountBaseToken);
        _baseTokens = _baseTokens.min(ERC20(order.baseToken).allowance(msg.sender, address(this)));
        _baseTokens = _baseTokens.min(ERC20(order.baseToken).balanceOf(msg.sender));
        // emit LogUint("_baseTokens=min", _baseTokens);

        // emit LogUint("order.amount x price / 1e18", order.amount.mul(order.price).div(ONEE18));
        // emit LogUint("amountBaseToken x price / 1e18", amountBaseToken.mul(order.price).div(ONEE18));
        // emit LogUint("quoteToken.balanceOf(msg.sender, this)", ERC20(order.quoteToken).balanceOf(address(this)));
        _quoteTokens = order.amount.mul(order.price).div(ONEE18);
        _quoteTokens = _quoteTokens.min(amountBaseToken.mul(order.price).div(ONEE18));
        _quoteTokens = _quoteTokens.min(ERC20(order.quoteToken).balanceOf(address(this)));
        // emit LogUint("_quoteTokens=min", _quoteTokens);

        _baseTokens = _baseTokens.min(_quoteTokens.mul(ONEE18).div(order.price));
        // emit LogUint("_baseTokens = min(_baseTokens, _quoteTokens x 1e18 / price)", _baseTokens);
        _quoteTokens = _baseTokens.mul(order.price).div(ONEE18);
        // emit LogUint("_quoteTokens = _baseTokens x price / 1e18", _quoteTokens);
        require(_baseTokens > 0 && _quoteTokens > 0);
        emit TakerSold(key, amountBaseToken, msg.sender, address(this), order.baseToken, order.quoteToken, _baseTokens, _quoteTokens);

        if (_baseTokens == order.amount) {
            orders.remove(key);
        } else {
            orders.orders[key].amount = orders.orders[key].amount.sub(_baseTokens);
        }

        uint balanceBefore = ERC20(order.baseToken).balanceOf(address(this));
        require(ERC20(order.baseToken).transferFrom(msg.sender, address(this), _baseTokens));
        uint balanceAfter = ERC20(order.baseToken).balanceOf(address(this));
        require(balanceBefore.add(_baseTokens) == balanceAfter);

        balanceBefore = ERC20(order.quoteToken).balanceOf(address(this));
        require(ERC20(order.quoteToken).transfer(msg.sender, _quoteTokens));
        balanceAfter = ERC20(order.quoteToken).balanceOf(address(this));
        require(balanceBefore == balanceAfter.add(_quoteTokens));
    }
    function takerBuy(bytes32 key, uint amountBaseToken) public returns (uint _baseTokens, uint _quoteTokens) {
        // BK TODO: Iterate of more than one order
        // BK TODO: Handle shrapnel

        Orders.Order memory order = orders.orders[key];
        require(now <= order.expiry);
        require(order.orderType == Orders.OrderType.SELL);

        // emit LogUint("order.amount x price / 1e18", order.amount.mul(order.price).div(ONEE18));
        // emit LogUint("amountBaseToken x price / 1e18", amountBaseToken.mul(order.price).div(ONEE18));
        // emit LogUint("quoteToken.allowance(msg.sender, this)", ERC20(order.quoteToken).allowance(msg.sender, address(this)));
        // emit LogUint("quoteToken.balanceOf(msg.sender, this)", ERC20(order.quoteToken).balanceOf(msg.sender));
        _quoteTokens = order.amount.mul(order.price).div(ONEE18);
        _quoteTokens = _quoteTokens.min(amountBaseToken.mul(order.price).div(ONEE18));
        _quoteTokens = _quoteTokens.min(ERC20(order.quoteToken).allowance(msg.sender, address(this)));
        _quoteTokens = _quoteTokens.min(ERC20(order.quoteToken).balanceOf(msg.sender));
        // emit LogUint("_quoteTokens=min", _quoteTokens);

        // emit LogUint("order.amount", order.amount);
        // emit LogUint("amountBaseToken", amountBaseToken);
        // emit LogUint("baseToken.balanceOf(this)", ERC20(order.baseToken).balanceOf(address(this)));
        _baseTokens = order.amount.min(amountBaseToken);
        _baseTokens = _baseTokens.min(ERC20(order.baseToken).balanceOf(address(this)));
        // emit LogUint("_baseTokens=min", _baseTokens);

        _baseTokens = _baseTokens.min(_quoteTokens.mul(ONEE18).div(order.price));
        // emit LogUint("_baseTokens = min(_baseTokens, _quoteTokens x 1e18 / price)", _baseTokens);
        _quoteTokens = _baseTokens.mul(order.price).div(ONEE18);
        // emit LogUint("_quoteTokens = _baseTokens x price / 1e18", _quoteTokens);
        require(_baseTokens > 0 && _quoteTokens > 0);
        emit TakerBought(key, amountBaseToken, msg.sender, address(this), order.baseToken, order.quoteToken, _baseTokens, _quoteTokens);

        if (_baseTokens == order.amount) {
            orders.remove(key);
        } else {
            orders.orders[key].amount = orders.orders[key].amount.sub(_baseTokens);
        }

        uint balanceBefore = ERC20(order.quoteToken).balanceOf(address(this));
        require(ERC20(order.quoteToken).transferFrom(msg.sender, address(this), _quoteTokens));
        uint balanceAfter = ERC20(order.quoteToken).balanceOf(address(this));
        require(balanceBefore.add(_quoteTokens) == balanceAfter);

        balanceBefore = ERC20(order.baseToken).balanceOf(address(this));
        require(ERC20(order.baseToken).transfer(msg.sender, _baseTokens));
        balanceAfter = ERC20(order.baseToken).balanceOf(address(this));
        require(balanceBefore == balanceAfter.add(_baseTokens));
    }


    function dexWalletExchangerTransfer(address token, address to, uint tokens) public onlyDEXWalletExchanger {
        uint balanceFromBefore = ERC20(token).balanceOf(address(this));
        uint balanceToBefore = ERC20(token).balanceOf(to);
        require(ERC20(token).transfer(to, tokens));
        uint balanceFromAfter = ERC20(token).balanceOf(address(this));
        uint balanceToAfter = ERC20(token).balanceOf(to);
        require(balanceFromBefore == balanceFromAfter.add(tokens));
        require(balanceToBefore.add(tokens) == balanceToAfter);
    }
/*

takerBuys(key, baseTokens)
  Taker sells (baseTokens x price / 1e18) quoteToken and Maker buys baseTokens baseToken
  -  Taker must approval and balance of (baseTokens x price / 1e18)
  -  Maker must have balance of baseTokens

takerSells(key, baseTokens)
  Taker buys quoteTokens quoteToken and Maker sells

Taker Maker   Pair        Price  Inv Price
----- ----- -------- ---------- ----------
Sell  Buy   GNT/ETH  0.00054087
Buy   Sell  GNT/ETH  0.00055087
Buy   Sell  ETH/GNT             0.00054087
Sell  Buy   ETH/GNT             0.00055087

if BUY, DEXWallet must have amount x price in quoteToken
if SELL, DEXWallet must have amount in baseToken

    // GNT/ETH = base/quote = 0.00054087
    struct Order {
        OrderType orderType;    // BUY
        address baseToken;      // GNT
        address quoteToken;     // ETH
        uint price;             // GNT/ETH = 0.00054087 = #quoteToken per unit baseToken
        uint amount;            // GNT - baseToken
    }
    // ETH/GNT = base/quote = 1848.873111838334535
    struct Order {
        OrderType orderType;    // SELL
        address baseToken;      // ETH
        address quoteToken;     // GNT
        uint price;             // ETH/GNT = 1848.873111838334535 = #quoteToken per unit baseToken
        uint amount;            // ETH - baseToken
    }
*/

    // NOTE - buyTokens = 0 will give you the maximum tokens that the wallet will buy and sell
    function getWalletBuyingDetails(bytes32 key, address buyToken, address sellToken, uint buyTokens) public view returns (uint _buyTokens, uint _sellTokens, uint _price, bool _inverse) {
        Orders.Order memory order = orders.orders[key];
        if (now <= order.expiry) {
            uint maxAmount;
            if (order.orderType == Orders.OrderType.BUY && buyToken == order.baseToken && sellToken == order.quoteToken) {
                maxAmount = ERC20(order.baseToken).balanceOf(address(this));
                if (maxAmount > order.amount) {
                    maxAmount = order.amount;
                }
                if (buyTokens == 0 || buyTokens > maxAmount) {
                    _buyTokens = maxAmount;
                } else {
                    _buyTokens = buyTokens;
                }
                _sellTokens = _buyTokens.mul(order.price).div(ONEE18);
                _price = order.price;
                _inverse = false;

            } else if (order.orderType == Orders.OrderType.SELL && buyToken == order.quoteToken && sellToken == order.baseToken) {
                maxAmount = ERC20(order.baseToken).balanceOf(address(this)).mul(order.price).div(ONEE18);
                if (maxAmount > ERC20(order.quoteToken).balanceOf(address(this))) {
                    maxAmount = ERC20(order.quoteToken).balanceOf(address(this));
                }
                if (maxAmount > order.amount.mul(order.price).div(ONEE18)) {
                    maxAmount = order.amount.mul(order.price).div(ONEE18);
                }
                if (buyTokens == 0 || buyTokens > maxAmount) {
                    _buyTokens = maxAmount;
                } else {
                    _buyTokens = buyTokens;
                }
                _sellTokens = _buyTokens.mul(1 ether).div(order.price);
                _price = (ONEE18).mul(ONEE18).div(order.price);
                _inverse = true;
            }
        }
    }
}


// ----------------------------------------------------------------------------
// DEXWalletFactory contract
// ----------------------------------------------------------------------------
contract DEXWalletExchanger is Owned {
    function exchange(address[] dexWallets, bytes32[] keys, uint[] baseTokens) public returns (uint _baseTokens, uint _quoteTokens) {
        require(dexWallets.length > 0 && dexWallets.length == keys.length && dexWallets.length == baseTokens.length);
    }
}


// ----------------------------------------------------------------------------
// DEXWalletFactory contract
// ----------------------------------------------------------------------------
contract DEXWalletFactory is CloneFactory, Owned {
    DEXWallet public walletTemplate;

    DEXWallet[] public wallets;
    mapping(address => address[]) public ownedWallets;
    mapping(address => bool) public dexWalletExchangers;
    address public currentDEXWalletExchanger;

    event WalletCreated(address indexed owner, address indexed dexWalletAddress);

    constructor() public {
        walletTemplate = new DEXWallet();
        currentDEXWalletExchanger = new DEXWalletExchanger();
        dexWalletExchangers[currentDEXWalletExchanger] = true;
        initOwned(msg.sender);
    }
    function newDEXWallet() public {
        newDEXWalletFor(msg.sender);
    }
    function setDEXWalletExchanger(address dexWalletExchanger, bool status) public onlyOwner {
        dexWalletExchangers[dexWalletExchanger] = status;
    }
    function setCurrentDEXWalletExchanger(address dexWalletExchanger) public onlyOwner {
        require(dexWalletExchangers[dexWalletExchanger] == true);
        currentDEXWalletExchanger = dexWalletExchanger;
    }
    function newDEXWalletFor(address _owner) public {
        DEXWallet newWallet = DEXWallet(createClone(address(walletTemplate)));
        newWallet.init(this, _owner, currentDEXWalletExchanger);
        wallets.push(newWallet);
        ownedWallets[msg.sender].push(newWallet);
        emit WalletCreated(_owner, address(newWallet));
    }
    function numberOfWallets() public view returns (uint) {
        return wallets.length;
    }
}
