// ETH/USD 29 Jun 2018 03:20 AEDT from CMC and ethgasstation.info
var ethPriceUSD = 435.65;
var defaultGasPrice = web3.toWei(2, "gwei");

// -----------------------------------------------------------------------------
// Accounts
// -----------------------------------------------------------------------------
var accounts = [];
var accountNames = {};

addAccount(eth.accounts[0], "Account #0 - Miner");
addAccount(eth.accounts[1], "Account #1 - Deployer");
addAccount(eth.accounts[2], "Account #2 - DEX Operator");
addAccount(eth.accounts[3], "Account #3 - User 1");
addAccount(eth.accounts[4], "Account #4 - User 2");
addAccount(eth.accounts[5], "Account #5 - User 3");
addAccount(eth.accounts[6], "Account #6");
addAccount(eth.accounts[7], "Account #7");
// addAccount(eth.accounts[8], "Account #8");
// addAccount(eth.accounts[9], "Account #9");
// addAccount(eth.accounts[10], "Account #10");
// addAccount(eth.accounts[11], "Account #11");

var minerAccount = eth.accounts[0];
var deployer = eth.accounts[1];
var dexOperator = eth.accounts[2];
var user1 = eth.accounts[3];
var user2 = eth.accounts[4];
var user3 = eth.accounts[5];
var account6 = eth.accounts[6];
var account7 = eth.accounts[7];
// var account8 = eth.accounts[8];
// var account9 = eth.accounts[9];
// var account10 = eth.accounts[10];
// var account11 = eth.accounts[11];

console.log("DATA: var minerAccount=\"" + eth.accounts[0] + "\";");
console.log("DATA: var deployer=\"" + eth.accounts[1] + "\";");
console.log("DATA: var dexOperator=\"" + eth.accounts[2] + "\";");
console.log("DATA: var user1=\"" + eth.accounts[3] + "\";");
console.log("DATA: var user2=\"" + eth.accounts[4] + "\";");
console.log("DATA: var user3=\"" + eth.accounts[5] + "\";");

var baseBlock = eth.blockNumber;

function unlockAccounts(password) {
  for (var i = 0; i < eth.accounts.length && i < accounts.length; i++) {
    personal.unlockAccount(eth.accounts[i], password, 100000);
    if (i > 0 && eth.getBalance(eth.accounts[i]) == 0) {
      personal.sendTransaction({from: eth.accounts[0], to: eth.accounts[i], value: web3.toWei(1000000, "ether")});
    }
  }
  while (txpool.status.pending > 0) {
  }
  baseBlock = eth.blockNumber;
}

function addAccount(account, accountName) {
  accounts.push(account);
  accountNames[account] = accountName;
  addAddressNames(account, accountName);
}


//-----------------------------------------------------------------------------
//Token A Contract
//-----------------------------------------------------------------------------
var tokenAContractAddress = null;
var tokenAContractAbi = null;

function addTokenAContractAddressAndAbi(address, abi) {
  tokenAContractAddress = address;
  tokenAContractAbi = abi;
}


//-----------------------------------------------------------------------------
//Token B Contract
//-----------------------------------------------------------------------------
var tokenBContractAddress = null;
var tokenBContractAbi = null;

function addTokenBContractAddressAndAbi(address, abi) {
  tokenBContractAddress = address;
  tokenBContractAbi = abi;
}


//-----------------------------------------------------------------------------
//Account ETH and token balances
//-----------------------------------------------------------------------------
function printBalances() {
  var tokenA = tokenAContractAddress == null || tokenAContractAbi == null ? null : web3.eth.contract(tokenAContractAbi).at(tokenAContractAddress);
  var tokenB = tokenBContractAddress == null || tokenBContractAbi == null ? null : web3.eth.contract(tokenBContractAbi).at(tokenBContractAddress);
  var decimalsA = tokenA == null ? 18 : tokenA.decimals();
  var decimalsB = tokenB == null ? 18 : tokenB.decimals();
  var i = 0;
  var totalTokenABalance = new BigNumber(0);
  var totalTokenBBalance = new BigNumber(0);
  // console.log("RESULT:  # Account                                             EtherBalanceChange                        Token A                        Token B Name");
  console.log("RESULT:  # Account                                             EtherBalanceChange               " + padLeft(tokenA.symbol(), 16) + "               " + padLeft(tokenB.symbol(), 16) + " Name");
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
  accounts.forEach(function(e) {
    var etherBalanceBaseBlock = eth.getBalance(e, baseBlock);
    var etherBalance = web3.fromWei(eth.getBalance(e).minus(etherBalanceBaseBlock), "ether");
    var tokenABalance = tokenA == null ? new BigNumber(0) : tokenA.balanceOf(e).shift(-decimalsA);
    var tokenBBalance = tokenB == null ? new BigNumber(0) : tokenB.balanceOf(e).shift(-decimalsB);
    totalTokenABalance = totalTokenABalance.add(tokenABalance);
    totalTokenBBalance = totalTokenBBalance.add(tokenBBalance);
    console.log("RESULT: " + pad2(i) + " " + e  + " " + pad(etherBalance) + " " +
      padToken(tokenABalance, decimalsA) + " " + padToken(tokenBBalance, decimalsB) + " " + accountNames[e]);
    i++;
  });
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
  console.log("RESULT:                                                                           " + padToken(totalTokenABalance, decimalsA) + " " + padToken(totalTokenBBalance, decimalsB) + " Total Token Balances");
  console.log("RESULT: -- ------------------------------------------ --------------------------- ------------------------------ ------------------------------ ---------------------------");
  console.log("RESULT: ");
}

function pad2(s) {
  var o = s.toFixed(0);
  while (o.length < 2) {
    o = " " + o;
  }
  return o;
}

function pad(s) {
  var o = s.toFixed(18);
  while (o.length < 27) {
    o = " " + o;
  }
  return o;
}

function padToken(s, decimals) {
  var o = s.toFixed(decimals);
  var l = parseInt(decimals)+12;
  while (o.length < l) {
    o = " " + o;
  }
  return o;
}

function padLeft(s, n) {
  var o = s;
  while (o.length < n) {
    o = " " + o;
  }
  return o;
}


// -----------------------------------------------------------------------------
// Transaction status
// -----------------------------------------------------------------------------
function printTxData(name, txId) {
  var tx = eth.getTransaction(txId);
  var txReceipt = eth.getTransactionReceipt(txId);
  var gasPrice = tx.gasPrice;
  var gasCostETH = tx.gasPrice.mul(txReceipt.gasUsed).div(1e18);
  var gasCostUSD = gasCostETH.mul(ethPriceUSD);
  var block = eth.getBlock(txReceipt.blockNumber);
  console.log("RESULT: " + name + " status=" + txReceipt.status + (txReceipt.status == 0 ? " Failure" : " Success") + " gas=" + tx.gas +
    " gasUsed=" + txReceipt.gasUsed + " costETH=" + gasCostETH + " costUSD=" + gasCostUSD +
    " @ ETH/USD=" + ethPriceUSD + " gasPrice=" + web3.fromWei(gasPrice, "gwei") + " gwei block=" +
    txReceipt.blockNumber + " txIx=" + tx.transactionIndex + " txId=" + txId +
    " @ " + block.timestamp + " " + new Date(block.timestamp * 1000).toUTCString());
}

function assertEtherBalance(account, expectedBalance) {
  var etherBalance = web3.fromWei(eth.getBalance(account), "ether");
  if (etherBalance == expectedBalance) {
    console.log("RESULT: OK " + account + " has expected balance " + expectedBalance);
  } else {
    console.log("RESULT: FAILURE " + account + " has balance " + etherBalance + " <> expected " + expectedBalance);
  }
}

function failIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 0) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfTxStatusError(tx, msg) {
  var status = eth.getTransactionReceipt(tx).status;
  if (status == 1) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function gasEqualsGasUsed(tx) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  return (gas == gasUsed);
}

function failIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    console.log("RESULT: PASS " + msg);
    return 1;
  }
}

function passIfGasEqualsGasUsed(tx, msg) {
  var gas = eth.getTransaction(tx).gas;
  var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
  if (gas == gasUsed) {
    console.log("RESULT: PASS " + msg);
    return 1;
  } else {
    console.log("RESULT: FAIL " + msg);
    return 0;
  }
}

function failIfGasEqualsGasUsedOrContractAddressNull(contractAddress, tx, msg) {
  if (contractAddress == null) {
    console.log("RESULT: FAIL " + msg);
    return 0;
  } else {
    var gas = eth.getTransaction(tx).gas;
    var gasUsed = eth.getTransactionReceipt(tx).gasUsed;
    if (gas == gasUsed) {
      console.log("RESULT: FAIL " + msg);
      return 0;
    } else {
      console.log("RESULT: PASS " + msg);
      return 1;
    }
  }
}


//-----------------------------------------------------------------------------
// Wait one block
//-----------------------------------------------------------------------------
function waitOneBlock(oldCurrentBlock) {
  while (eth.blockNumber <= oldCurrentBlock) {
  }
  console.log("RESULT: Waited one block");
  console.log("RESULT: ");
  return eth.blockNumber;
}


//-----------------------------------------------------------------------------
// Pause for {x} seconds
//-----------------------------------------------------------------------------
function pause(message, addSeconds) {
  var time = new Date((parseInt(new Date().getTime()/1000) + addSeconds) * 1000);
  console.log("RESULT: Pausing '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
  while ((new Date()).getTime() <= time.getTime()) {
  }
  console.log("RESULT: Paused '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
//Wait until some unixTime + additional seconds
//-----------------------------------------------------------------------------
function waitUntil(message, unixTime, addSeconds) {
  var t = parseInt(unixTime) + parseInt(addSeconds) + parseInt(1);
  var time = new Date(t * 1000);
  console.log("RESULT: Waiting until '" + message + "' at " + unixTime + "+" + addSeconds + "s=" + time + " now=" + new Date());
  while ((new Date()).getTime() <= time.getTime()) {
  }
  console.log("RESULT: Waited until '" + message + "' at at " + unixTime + "+" + addSeconds + "s=" + time + " now=" + new Date());
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
//Wait until some block
//-----------------------------------------------------------------------------
function waitUntilBlock(message, block, addBlocks) {
  var b = parseInt(block) + parseInt(addBlocks) + parseInt(1);
  console.log("RESULT: Waiting until '" + message + "' #" + block + "+" + addBlocks + "=#" + b + " currentBlock=" + eth.blockNumber);
  while (eth.blockNumber <= b) {
  }
  console.log("RESULT: Waited until '" + message + "' #" + block + "+" + addBlocks + "=#" + b + " currentBlock=" + eth.blockNumber);
  console.log("RESULT: ");
}


//-----------------------------------------------------------------------------
// Token Contract A
//-----------------------------------------------------------------------------
var tokenAFromBlock = 0;
function printTokenAContractDetails() {
  console.log("RESULT: tokenAContractAddress=" + getAddressName(tokenAContractAddress));
  if (tokenAContractAddress != null && tokenAContractAbi != null) {
    var contract = eth.contract(tokenAContractAbi).at(tokenAContractAddress);
    var decimals = contract.decimals();
    console.log("RESULT: tokenA.owner/new=" + getAddressName(contract.owner()) + " " + getAddressName(contract.newOwner()));
    console.log("RESULT: tokenA.details='" + contract.symbol() + "' '" + contract.name() + "' " + decimals);
    console.log("RESULT: tokenA.totalSupply=" + contract.totalSupply() + " " + contract.totalSupply().shift(-decimals));

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: tokenA.OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var approvalEvents = contract.Approval({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      console.log("RESULT: tokenA.Approval " + i++ + " #" + result.blockNumber + " tokenOwner=" + getShortAddressName(result.args.tokenOwner) +
        " spender=" + getShortAddressName(result.args.spender) + " tokens=" + result.args.tokens.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contract.Transfer({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      console.log("RESULT: tokenA.Transfer " + i++ + " #" + result.blockNumber + ": from=" + getShortAddressName(result.args.from) +
        " to=" + getShortAddressName(result.args.to) + " tokens=" + result.args.tokens.shift(-decimals));
    });
    transferEvents.stopWatching();

    tokenAFromBlock = latestBlock + 1;
  }
}


//-----------------------------------------------------------------------------
// Token Contract B
//-----------------------------------------------------------------------------
var tokenBFromBlock = 0;
function printTokenBContractDetails() {
  console.log("RESULT: tokenBContractAddress=" + getAddressName(tokenBContractAddress));
  if (tokenBContractAddress != null && tokenBContractAbi != null) {
    var contract = eth.contract(tokenBContractAbi).at(tokenBContractAddress);
    var decimals = contract.decimals();
    console.log("RESULT: tokenB.owner/new=" + getAddressName(contract.owner()) + " " + getAddressName(contract.newOwner()));
    console.log("RESULT: tokenB.details='" + contract.symbol() + "' '" + contract.name() + "' " + decimals);
    console.log("RESULT: tokenB.totalSupply=" + contract.totalSupply() + " " + contract.totalSupply().shift(-decimals));

    var latestBlock = eth.blockNumber;
    var i;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: tokenBFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: tokenB.OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var approvalEvents = contract.Approval({}, { fromBlock: tokenBFromBlock, toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      console.log("RESULT: tokenB.Approval " + i++ + " #" + result.blockNumber + " tokenOwner=" + getShortAddressName(result.args.tokenOwner) +
        " spender=" + getShortAddressName(result.args.spender) + " tokens=" + result.args.tokens.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contract.Transfer({}, { fromBlock: tokenBFromBlock, toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      console.log("RESULT: tokenB.Transfer " + i++ + " #" + result.blockNumber + ": from=" + getShortAddressName(result.args.from) +
        " to=" + getShortAddressName(result.args.to) + " tokens=" + result.args.tokens.shift(-decimals));
    });
    transferEvents.stopWatching();

    tokenBFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// DEXWalletFactory Contract
// -----------------------------------------------------------------------------
var dexWalletFactoryContractAddress = null;
var dexWalletFactoryContractAbi = null;

function addDEXWalletFactoryContractAddressAndAbi(address, dexWalletFactoryAbi) {
  dexWalletFactoryContractAddress = address;
  dexWalletFactoryContractAbi = dexWalletFactoryAbi;
}

var dexWalletFactoryFromBlock = 0;
function getNewDEXWallet() {
  if (dexWalletFactoryFromBlock == 0) {
    dexWalletFactoryFromBlock = baseBlock;
  }
  var wallets = {};
  console.log("RESULT: dexWalletFactoryContractAddress=" + dexWalletFactoryContractAddress);
  if (dexWalletFactoryContractAddress != null && dexWalletFactoryContractAbi != null) {
    var contract = eth.contract(dexWalletFactoryContractAbi).at(dexWalletFactoryContractAddress);

    var latestBlock = eth.blockNumber;
    var i;

    var walletCreatedEvents = contract.WalletCreated({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    walletCreatedEvents.watch(function (error, result) {
      console.log("RESULT: getNewDEXWallet.WalletCreated " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
      wallets[result.args.owner] = result.args.dexWalletAddress;
    });
    walletCreatedEvents.stopWatching();
  }
  return wallets;
}
function printDEXWalletFactoryContractDetails() {
  if (dexWalletFactoryFromBlock == 0) {
    dexWalletFactoryFromBlock = baseBlock;
  }
  console.log("RESULT: dexWalletFactory.address=" + getAddressName(dexWalletFactoryContractAddress));
  if (dexWalletFactoryContractAddress != null && dexWalletFactoryContractAbi != null) {
    var contract = eth.contract(dexWalletFactoryContractAbi).at(dexWalletFactoryContractAddress);
    console.log("RESULT: dexWalletFactory.owner/new=" + getAddressName(contract.owner()) + " " + getAddressName(contract.newOwner()));
    // console.log("RESULT: dexWalletFactory.wallets=" + JSON.stringify(contract.wallets()));
    // console.log("RESULT: dexWalletFactory.ownedWallets(user1)=" + JSON.stringify(contract.ownedWallets(user1)));
    // console.log("RESULT: dexWalletFactory.ownedWallets(user2)=" + JSON.stringify(contract.ownedWallets(user2)));
    // console.log("RESULT: dexWalletFactory.ownedWallets(user3)=" + JSON.stringify(contract.ownedWallets(user3)));
    console.log("RESULT: dexWalletFactory.walletTemplate=" + contract.walletTemplate());
    console.log("RESULT: dexWalletFactory.numberOfWallets=" + contract.numberOfWallets());

    var i;
    for (i = 0; i < contract.numberOfWallets(); i++) {
      var walletAddress = contract.wallets(i);
      // var owner = contract.optionDetails(optionAddress);
      console.log("RESULT: dexWalletFactory.wallets[" + i + "]=" + walletAddress);
    }

    var latestBlock = eth.blockNumber;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var walletCreatedEvents = contract.WalletCreated({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    walletCreatedEvents.watch(function (error, result) {
      console.log("RESULT: WalletCreated " + i++ + " #" + result.blockNumber + " owner=" + result.args.owner +
        " dexWalletAddress=" + result.args.dexWalletAddress);
    });
    walletCreatedEvents.stopWatching();

    dexWalletFactoryFromBlock = latestBlock + 1;
  }
}


function formatOrder(key, orderType, baseTokenAddress, quoteTokenAddress, price, expiry, amount) {
  var baseToken = getAddressSymbol(baseTokenAddress);
  var quoteToken = getAddressSymbol(quoteTokenAddress);
  return key + " " + (orderType == 0 ? "BUY" : "SELL") + " " + amount.shift(-18) + " " + baseToken + "[b] @ " + price.shift(-18) + " " +
    baseToken + "[b] per unit " + quoteToken + "[q] until " + new Date(expiry * 1000).toString();
}
function formatEffectiveOrder(effectiveOrder) {
  var orderType = effectiveOrder[0];
  var baseToken = getAddressSymbol(effectiveOrder[1]);
  var quoteToken = getAddressSymbol(effectiveOrder[2]);
  var price = effectiveOrder[3];
  var expiry = effectiveOrder[4];
  var baseAmount = effectiveOrder[5];
  var quoteAmount = effectiveOrder[6];
  return (orderType == 0 ? "BUY" : "SELL") + " baseAmount=" + baseAmount.shift(-18) + " quoteAmount=" + quoteAmount.shift(-18) + " " + baseToken + "[b] @ " + price.shift(-18) + " " +
    baseToken + "/" + quoteToken + " until " + new Date(expiry * 1000).toString();
}
// function getEffectiveOrder(bytes32 key) public view returns (uint _orderType, address _baseToken, address _quoteToken, uint _price, uint _expiry, uint _baseAmount, uint _quoteAmount);


var fromBlock = {};
function printDEXWalletContractDetails(address, abi) {
  if (fromBlock[address] == 0) {
    fromBlock[address] = baseBlock;
  }
  console.log("RESULT: dexWallet.address=" + getAddressName(address));
  if (address != null && abi != null) {
    var contract = eth.contract(abi).at(address);
    console.log("RESULT: dexWallet.owner/new=" + getAddressName(contract.owner()) + " " + getAddressName(contract.newOwner()));

    var i;
    for (i = 0; i < contract.getNumberOfOrders(); i++) {
       var orderKey = contract.getOrderKeyByIndex(i);
       var order = contract.getOrderByKey(orderKey);
       var effectiveOrder = contract.getEffectiveOrder(orderKey);
       console.log("RESULT: dexWallet.orders.index[" + i + "]=" + formatOrder(order[0], order[1], order[2], order[3], order[4], order[5], order[6]));
       console.log("RESULT:   effectiveOrder=" + formatEffectiveOrder(effectiveOrder));
    }

    var latestBlock = eth.blockNumber;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: fromBlock[address], toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var orderAddedEvents = contract.OrderAdded({}, { fromBlock: fromBlock[address], toBlock: latestBlock });
    i = 0;
    orderAddedEvents.watch(function (error, result) {
      console.log("RESULT: dexWallet.OrderAdded " + i++ + " #" + result.blockNumber + " " +
        formatOrder(result.args.key, result.args.orderType, result.args.baseToken, result.args.quoteToken, result.args.price, result.args.expiry, result.args.amount));
    });
    orderAddedEvents.stopWatching();

    var orderRemovedEvents = contract.OrderRemoved({}, { fromBlock: fromBlock[address], toBlock: latestBlock });
    i = 0;
    orderRemovedEvents.watch(function (error, result) {
      console.log("RESULT: dexWallet.OrderRemoved " + i++ + " #" + result.blockNumber + " " +
        formatOrder(result.args.key, result.args.orderType, result.args.baseToken, result.args.quoteToken, result.args.price, result.args.expiry, result.args.amount));
    });
    orderRemovedEvents.stopWatching();

    var takerSoldEvents = contract.TakerSold({}, { fromBlock: fromBlock[address], toBlock: latestBlock });
    i = 0;
    takerSoldEvents.watch(function (error, result) {
      console.log("RESULT: TakerSold " + i++ + " #" + result.blockNumber + " key=" + result.args.key + " amount=" + result.args.amount.shift(-18) +
        " taker=" + getShortAddressName(result.args.taker) + " maker=" + getShortAddressName(result.args.maker) +
        " baseToken=" + getAddressSymbol(result.args.baseToken) + " quoteToken=" + getAddressSymbol(result.args.quoteToken) +
        " baseTokens=" + result.args.baseTokens.shift(-18) + " quoteTokens=" + result.args.quoteTokens.shift(-18));
    });
    takerSoldEvents.stopWatching();

    var takerBoughtEvents = contract.TakerBought({}, { fromBlock: fromBlock[address], toBlock: latestBlock });
    i = 0;
    takerBoughtEvents.watch(function (error, result) {
      console.log("RESULT: TakerBought " + i++ + " #" + result.blockNumber + " key=" + result.args.key + " amount=" + result.args.amount.shift(-18) +
        " taker=" + getShortAddressName(result.args.taker) + " maker=" + getShortAddressName(result.args.maker) +
        " baseToken=" + getAddressSymbol(result.args.baseToken) + " quoteToken=" + getAddressSymbol(result.args.quoteToken) +
        " baseTokens=" + result.args.baseTokens.shift(-18) + " quoteTokens=" + result.args.quoteTokens.shift(-18));
    });
    takerBoughtEvents.stopWatching();

    var logUintEvents = contract.LogUint({}, { fromBlock: fromBlock[address], toBlock: latestBlock });
    i = 0;
    logUintEvents.watch(function (error, result) {
      console.log("RESULT: LogUint " + i++ + " #" + result.blockNumber + " " + result.args.note + " = " + result.args.number.shift(-18));
    });
    logUintEvents.stopWatching();

    fromBlock[address] = latestBlock + 1;
  }
}
