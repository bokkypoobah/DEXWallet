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
addAccount(eth.accounts[8], "Account #8");
addAccount(eth.accounts[9], "Account #9");
addAccount(eth.accounts[10], "Account #10");
addAccount(eth.accounts[11], "Account #11");

var minerAccount = eth.accounts[0];
var deployer = eth.accounts[1];
var dexOperator = eth.accounts[2];
var user1 = eth.accounts[3];
var user2 = eth.accounts[4];
var user3 = eth.accounts[5];
var account6 = eth.accounts[6];
var account7 = eth.accounts[7];
var account8 = eth.accounts[8];
var account9 = eth.accounts[9];
var account10 = eth.accounts[10];
var account11 = eth.accounts[11];

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
  console.log("RESULT:  # Account                                             EtherBalanceChange                 (Token A) WETH                  (Token B) DAI Name");
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
    console.log("RESULT: token.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: token.owner=" + getAddressName(contract.owner()));
    console.log("RESULT: token.erc20Authority=" + getAddressName(contract.erc20Authority()));
    console.log("RESULT: token.tokenAuthority=" + getAddressName(contract.tokenAuthority()));
    console.log("RESULT: token.transferFeeController=" + getAddressName(contract.transferFeeController()));
    console.log("RESULT: token.transferFeeCollector=" + getAddressName(contract.transferFeeCollector()));
    console.log("RESULT: token.symbol=" + web3.toUtf8(contract.symbol()));
    console.log("RESULT: token.name=" + web3.toUtf8(contract.name()));
    console.log("RESULT: token.decimals=" + decimals);
    console.log("RESULT: token.totalSupply=" + contract.totalSupply() + " " + contract.totalSupply().shift(-decimals));

    var latestBlock = eth.blockNumber;
    var i;

    var logSetAuthorityEvents = contract.LogSetAuthority({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    logSetAuthorityEvents.watch(function (error, result) {
      console.log("RESULT: token.LogSetAuthority " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetAuthorityEvents.stopWatching();

    var logSetOwnerEvents = contract.LogSetOwner({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    logSetOwnerEvents.watch(function (error, result) {
      console.log("RESULT: token.LogSetOwner " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetOwnerEvents.stopWatching();

    var logNoteEvents = contract.LogNote({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    logNoteEvents.watch(function (error, result) {
      console.log("RESULT: token.LogNote " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logNoteEvents.stopWatching();

    var mintEvents = contract.Mint({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    mintEvents.watch(function (error, result) {
      console.log("RESULT: token.Mint " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    mintEvents.stopWatching();

    var burnEvents = contract.Burn({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    burnEvents.watch(function (error, result) {
      console.log("RESULT: token.Burn " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    burnEvents.stopWatching();

    var approvalEvents = contract.Approval({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      console.log("RESULT: token.Approval " + i++ + " #" + result.blockNumber + " src=" + result.args.src +
        " guy=" + result.args.guy + " wad=" + result.args.wad.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contract.Transfer({}, { fromBlock: tokenAFromBlock, toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      console.log("RESULT: token.Transfer " + i++ + " #" + result.blockNumber + ": src=" + result.args.src + " dst=" + result.args.dst +
        " wad=" + result.args.wad.shift(-decimals));
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
  console.log("RESULT: tokenBContractAddress=" + tokenBContractAddress);
  if (tokenBContractAddress != null && tokenBContractAbi != null) {
    var contract = eth.contract(tokenBContractAbi).at(tokenBContractAddress);
    var decimals = contract.decimals();
    console.log("RESULT: token.owner=" + contract.owner());
    console.log("RESULT: token.newOwner=" + contract.newOwner());
    console.log("RESULT: token.symbol=" + contract.symbol());
    console.log("RESULT: token.name=" + contract.name());
    console.log("RESULT: token.decimals=" + decimals);
    console.log("RESULT: token.totalSupply=" + contract.totalSupply().shift(-decimals));
    console.log("RESULT: token.initialised=" + contract.initialised());

    var latestBlock = eth.blockNumber;
    var i;

    var approvalEvents = contract.Approval({}, { fromBlock: tokenBFromBlock, toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      console.log("RESULT: Approval " + i++ + " #" + result.blockNumber + " owner=" + result.args.owner +
        " spender=" + result.args.spender + " tokens=" + result.args.tokens.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contract.Transfer({}, { fromBlock: tokenBFromBlock, toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      console.log("RESULT: Transfer " + i++ + " #" + result.blockNumber + ": from=" + result.args.from + " to=" + result.args.to +
        " tokens=" + result.args.tokens.shift(-decimals));
    });
    transferEvents.stopWatching();

    tokenBFromBlock = latestBlock + 1;
  }
}


function roleNames(role) {
  if (role == 1) {
    return "SYSTEM_ADMIN:1";
  } else if (role == 2) {
    return "KYC_OPERATOR:2";
  } else if (role == 3) {
    return "MONEY_OPERATOR:3";
  } else {
    return "UNKNOWN:" + role;
  }
}

// -----------------------------------------------------------------------------
// GateRoles Contract
// -----------------------------------------------------------------------------
var gateRolesContractAddress = null;
var gateRolesContractAbi = null;

function addGateRolesContractAddressAndAbi(address, abi) {
  gateRolesContractAddress = address;
  gateRolesContractAbi = abi;
}

var gateRolesFromBlock = 0;
function printGateRolesContractDetails() {
  if (gateRolesFromBlock == 0) {
    gateRolesFromBlock = baseBlock;
  }
  console.log("RESULT: gateRoles.address=" + getAddressName(gateRolesContractAddress));
  if (gateRolesContractAddress != null && gateRolesContractAbi != null) {
    var contract = eth.contract(gateRolesContractAbi).at(gateRolesContractAddress);
    console.log("RESULT: gateRoles.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: gateRoles.owner=" + getAddressName(contract.owner()));
    console.log("RESULT: gateRoles.SYSTEM_ADMIN=" + roleNames(contract.SYSTEM_ADMIN()));
    console.log("RESULT: gateRoles.KYC_OPERATOR=" + roleNames(contract.KYC_OPERATOR()));
    console.log("RESULT: gateRoles.MONEY_OPERATOR=" + roleNames(contract.MONEY_OPERATOR()));

    var latestBlock = eth.blockNumber;
    var i;

    var logSetAuthorityEvents = contract.LogSetAuthority({}, { fromBlock: gateRolesFromBlock, toBlock: latestBlock });
    i = 0;
    logSetAuthorityEvents.watch(function (error, result) {
      console.log("RESULT: gateRoles.LogSetAuthority " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetAuthorityEvents.stopWatching();

    var logSetOwnerEvents = contract.LogSetOwner({}, { fromBlock: gateRolesFromBlock, toBlock: latestBlock });
    i = 0;
    logSetOwnerEvents.watch(function (error, result) {
      console.log("RESULT: gateRoles.LogSetOwner " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetOwnerEvents.stopWatching();

    var logSetRootUserEvents = contract.LogSetRootUser({}, { fromBlock: gateRolesFromBlock, toBlock: latestBlock });
    i = 0;
    logSetRootUserEvents.watch(function (error, result) {
      console.log("RESULT: gateRoles.LogSetRootUser " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetRootUserEvents.stopWatching();

    var logSetUserRoleEvents = contract.LogSetUserRole({}, { fromBlock: gateRolesFromBlock, toBlock: latestBlock });
    i = 0;
    logSetUserRoleEvents.watch(function (error, result) {
      console.log("RESULT: gateRoles.LogSetUserRole " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetUserRoleEvents.stopWatching();

    var logSetPublicCapabilityEvents = contract.LogSetPublicCapability({}, { fromBlock: gateRolesFromBlock, toBlock: latestBlock });
    i = 0;
    logSetPublicCapabilityEvents.watch(function (error, result) {
      console.log("RESULT: gateRoles.LogSetPublicCapability " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetPublicCapabilityEvents.stopWatching();

    var logSetRoleCapabilityEvents = contract.LogSetRoleCapability({}, { fromBlock: gateRolesFromBlock, toBlock: latestBlock });
    i = 0;
    logSetRoleCapabilityEvents.watch(function (error, result) {
      var sig = sigs[result.args.sig.substring(0, 10)];
      if (sig !== undefined) {
        console.log("RESULT: gateRoles.RoleCapability code " + getAddressName(result.args.code) + " capabilityRoles " + result.args.capabilityRoles +
          " for " + sig + " role " + roleNames(result.args.role) + " " + result.args.enabled + " #" + result.blockNumber + " " + result.transactionHash);
      } else {
        console.log("RESULT: gateRoles.LogSetRoleCapability " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
      }
    });
    logSetRoleCapabilityEvents.stopWatching();

    gateRolesFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// TokenGuard Contract
// -----------------------------------------------------------------------------
var tokenGuardContractAddress = null;
var tokenGuardContractAbi = null;

function addTokenGuardContractAddressAndAbi(address, abi) {
  tokenGuardContractAddress = address;
  tokenGuardContractAbi = abi;
}

var tokenGuardFromBlock = 0;
function printTokenGuardContractDetails() {
  if (tokenGuardFromBlock == 0) {
    tokenGuardFromBlock = baseBlock;
  }
  console.log("RESULT: tokenGuard.address=" + getAddressName(tokenGuardContractAddress));
  if (tokenGuardContractAddress != null && tokenGuardContractAbi != null) {
    var contract = eth.contract(tokenGuardContractAbi).at(tokenGuardContractAddress);
    console.log("RESULT: tokenGuard.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: tokenGuard.owner=" + getAddressName(contract.owner()));

    var latestBlock = eth.blockNumber;
    var i;

    var logSetAuthorityEvents = contract.LogSetAuthority({}, { fromBlock: tokenGuardFromBlock, toBlock: latestBlock });
    i = 0;
    logSetAuthorityEvents.watch(function (error, result) {
      console.log("RESULT: tokenGuard.LogSetAuthority " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetAuthorityEvents.stopWatching();

    var logSetOwnerEvents = contract.LogSetOwner({}, { fromBlock: tokenGuardFromBlock, toBlock: latestBlock });
    i = 0;
    logSetOwnerEvents.watch(function (error, result) {
      console.log("RESULT: tokenGuard.LogSetOwner " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetOwnerEvents.stopWatching();

    var logPermitEvents = contract.LogPermit({}, { fromBlock: tokenGuardFromBlock, toBlock: latestBlock });
    i = 0;
    logPermitEvents.watch(function (error, result) {
      var sig = sigs[result.args.sig.substring(0, 10)];
      var src = "0x" + result.args.src.substring(26);
      var dst = "0x" + result.args.dst.substring(26);
      if (sig !== undefined) {
        console.log("RESULT: tokenGuard.Permit from " + getAddressName(src) + " to " + getAddressName(dst) + " for " + sig + " #" + result.blockNumber + " " + result.transactionHash);
      } else {
        console.log("RESULT: tokenGuard.LogPermit " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
      }
    });
    logPermitEvents.stopWatching();

    var logForbidEvents = contract.LogForbid({}, { fromBlock: tokenGuardFromBlock, toBlock: latestBlock });
    i = 0;
    logForbidEvents.watch(function (error, result) {
      console.log("RESULT: tokenGuard.LogForbid " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logForbidEvents.stopWatching();

    tokenGuardFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// KycAmlStatus Contract
// -----------------------------------------------------------------------------
var kycAmlStatusContractAddress = null;
var kycAmlStatusContractAbi = null;

function addKycAmlStatusContractAddressAndAbi(address, abi) {
  kycAmlStatusContractAddress = address;
  kycAmlStatusContractAbi = abi;
}

var kycAmlStatusFromBlock = 0;
function printKycAmlStatusContractDetails() {
  if (kycAmlStatusFromBlock == 0) {
    kycAmlStatusFromBlock = baseBlock;
  }
  console.log("RESULT: kycAmlStatus.address=" + getAddressName(kycAmlStatusContractAddress));
  if (kycAmlStatusContractAddress != null && kycAmlStatusContractAbi != null) {
    var contract = eth.contract(kycAmlStatusContractAbi).at(kycAmlStatusContractAddress);
    console.log("RESULT: kycAmlStatus.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: kycAmlStatus.owner=" + getAddressName(contract.owner()));

    var latestBlock = eth.blockNumber;
    var i;

    var kycVerifyEvents = contract.KYCVerify({}, { fromBlock: kycAmlStatusFromBlock, toBlock: latestBlock });
    i = 0;
    kycVerifyEvents.watch(function (error, result) {
      console.log("RESULT: kycAmlStatus.KYCVerify " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    kycVerifyEvents.stopWatching();

    kycAmlStatusFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// AddressControlStatus Contract
// -----------------------------------------------------------------------------
var addressControlStatusContractAddress = null;
var addressControlStatusContractAbi = null;

function addAddressControlStatusContractAddressAndAbi(address, abi) {
  addressControlStatusContractAddress = address;
  addressControlStatusContractAbi = abi;
}

var addressControlStatusFromBlock = 0;
function printAddressControlStatusContractDetails() {
  if (addressControlStatusFromBlock == 0) {
    addressControlStatusFromBlock = baseBlock;
  }
  console.log("RESULT: addressControlStatus.address=" + getAddressName(addressControlStatusContractAddress));
  if (addressControlStatusContractAddress != null && addressControlStatusContractAbi != null) {
    var contract = eth.contract(addressControlStatusContractAbi).at(addressControlStatusContractAddress);
    console.log("RESULT: addressControlStatus.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: addressControlStatus.owner=" + getAddressName(contract.owner()));

    var latestBlock = eth.blockNumber;
    var i;

    var freezeAddressEvents = contract.FreezeAddress({}, { fromBlock: addressControlStatusFromBlock, toBlock: latestBlock });
    i = 0;
    freezeAddressEvents.watch(function (error, result) {
      console.log("RESULT: addressControlStatus.FreezeAddress " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    freezeAddressEvents.stopWatching();

    var unfreezeAddressEvents = contract.UnfreezeAddress({}, { fromBlock: addressControlStatusFromBlock, toBlock: latestBlock });
    i = 0;
    unfreezeAddressEvents.watch(function (error, result) {
      console.log("RESULT: addressControlStatus.UnfreezeAddress " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    unfreezeAddressEvents.stopWatching();

    addressControlStatusFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// TransferFeeController Contract
// -----------------------------------------------------------------------------
var transferFeeControllerContractAddress = null;
var transferFeeControllerContractAbi = null;

function addTransferFeeControllerContractAddressAndAbi(address, abi) {
  transferFeeControllerContractAddress = address;
  transferFeeControllerContractAbi = abi;
}

var transferFeeControllerFromBlock = 0;
function printTransferFeeControllerContractDetails() {
  if (transferFeeControllerFromBlock == 0) {
    transferFeeControllerFromBlock = baseBlock;
  }
  console.log("RESULT: transferFeeController.address=" + getAddressName(transferFeeControllerContractAddress));
  if (transferFeeControllerContractAddress != null && transferFeeControllerContractAbi != null) {
    var contract = eth.contract(transferFeeControllerContractAbi).at(transferFeeControllerContractAddress);
    console.log("RESULT: transferFeeController.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: transferFeeController.owner=" + getAddressName(contract.owner()));
    console.log("RESULT: transferFeeController.defaultTransferFeeAbs=" + contract.defaultTransferFeeAbs());
    console.log("RESULT: transferFeeController.defaultTransferFeeBps=" + contract.defaultTransferFeeBps());

    var latestBlock = eth.blockNumber;
    var i;

    // No events

    transferFeeControllerFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// LimitSetting Contract
// -----------------------------------------------------------------------------
var limitSettingContractAddress = null;
var limitSettingContractAbi = null;

function addLimitSettingContractAddressAndAbi(address, abi) {
  limitSettingContractAddress = address;
  limitSettingContractAbi = abi;
}

var limitSettingFromBlock = 0;
function printLimitSettingContractDetails() {
  if (limitSettingFromBlock == 0) {
    limitSettingFromBlock = baseBlock;
  }
  console.log("RESULT: limitSetting.address=" + getAddressName(limitSettingContractAddress));
  if (limitSettingContractAddress != null && limitSettingContractAbi != null) {
    var contract = eth.contract(limitSettingContractAbi).at(limitSettingContractAddress);
    console.log("RESULT: limitSetting.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: limitSetting.owner=" + getAddressName(contract.owner()));
    console.log("RESULT: limitSetting.stopped=" + contract.stopped());
    console.log("RESULT: limitSetting.limitCounterResetTimeOffset=" + contract.limitCounterResetTimeOffset());
    console.log("RESULT: limitSetting.lastSettingResetTime=" + contract.lastSettingResetTime() + " " + new Date(contract.lastSettingResetTime() * 1000).toUTCString());
    console.log("RESULT: limitSetting.defaultDelayHours=" + contract.defaultDelayHours());
    console.log("RESULT: limitSetting.defaultDelayHoursBuffer=" + contract.defaultDelayHoursBuffer());
    console.log("RESULT: limitSetting.lastDefaultDelayHoursSettingResetTime=" + contract.lastDefaultDelayHoursSettingResetTime());
    console.log("RESULT: limitSetting.defaultMintDailyLimit=" + contract.defaultMintDailyLimit() + " " + contract.defaultMintDailyLimit().shift(-18));
    console.log("RESULT: limitSetting.defaultBurnDailyLimit=" + contract.defaultBurnDailyLimit() + " " + contract.defaultBurnDailyLimit().shift(-18));
    console.log("RESULT: limitSetting.defaultMintDailyLimitBuffer=" + contract.defaultMintDailyLimitBuffer() + " " + contract.defaultMintDailyLimitBuffer().shift(-18));
    console.log("RESULT: limitSetting.defaultBurnDailyLimitBuffer=" + contract.defaultBurnDailyLimitBuffer() + " " + contract.defaultBurnDailyLimitBuffer().shift(-18));

    var latestBlock = eth.blockNumber;
    var i;

    // NOTE that there are 2 versions of AdjustMintLimitRequested and AdjustBurnLimitRequested

    var logSetAuthorityEvents = contract.LogSetAuthority({}, { fromBlock: limitSettingFromBlock, toBlock: latestBlock });
    i = 0;
    logSetAuthorityEvents.watch(function (error, result) {
      console.log("RESULT: limitSetting.LogSetAuthority " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetAuthorityEvents.stopWatching();

    var logSetOwnerEvents = contract.LogSetOwner({}, { fromBlock: limitSettingFromBlock, toBlock: latestBlock });
    i = 0;
    logSetOwnerEvents.watch(function (error, result) {
      console.log("RESULT: limitSetting.LogSetOwner " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetOwnerEvents.stopWatching();

    var logNoteEvents = contract.LogNote({}, { fromBlock: limitSettingFromBlock, toBlock: latestBlock });
    i = 0;
    logNoteEvents.watch(function (error, result) {
      console.log("RESULT: limitSetting.LogNote " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logNoteEvents.stopWatching();

    var adjustMintLimitRequestedEvents = contract.AdjustMintLimitRequested({}, { fromBlock: limitSettingFromBlock, toBlock: latestBlock });
    i = 0;
    adjustMintLimitRequestedEvents.watch(function (error, result) {
      console.log("RESULT: limitSetting.AdjustMintLimitRequested " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    adjustMintLimitRequestedEvents.stopWatching();

    var adjustBurnLimitRequestedEvents = contract.AdjustBurnLimitRequested({}, { fromBlock: limitSettingFromBlock, toBlock: latestBlock });
    i = 0;
    adjustBurnLimitRequestedEvents.watch(function (error, result) {
      console.log("RESULT: limitSetting.AdjustBurnLimitRequested " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    adjustBurnLimitRequestedEvents.stopWatching();

    limitSettingFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// NoKycAmlRule Contract
// -----------------------------------------------------------------------------
var noKycAmlRuleContractAddress = null;
var noKycAmlRuleContractAbi = null;

function addNoKycAmlRuleContractAddressAndAbi(address, abi) {
  noKycAmlRuleContractAddress = address;
  noKycAmlRuleContractAbi = abi;
}

var noKycAmlRuleFromBlock = 0;
function printNoKycAmlRuleContractDetails() {
  if (noKycAmlRuleFromBlock == 0) {
    noKycAmlRuleFromBlock = baseBlock;
  }
  console.log("RESULT: noKycAmlRule.address=" + getAddressName(noKycAmlRuleContractAddress));
  if (noKycAmlRuleContractAddress != null && noKycAmlRuleContractAbi != null) {
    var contract = eth.contract(noKycAmlRuleContractAbi).at(noKycAmlRuleContractAddress);
    console.log("RESULT: noKycAmlRule.addressControlStatus=" + getAddressName(contract.addressControlStatus()));

    var latestBlock = eth.blockNumber;
    var i;

    // No events

    noKycAmlRuleFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// BoundaryKycAmlRule Contract
// -----------------------------------------------------------------------------
var boundaryKycAmlRuleContractAddress = null;
var boundaryKycAmlRuleContractAbi = null;

function addBoundaryKycAmlRuleContractAddressAndAbi(address, abi) {
  boundaryKycAmlRuleContractAddress = address;
  boundaryKycAmlRuleContractAbi = abi;
}

var boundaryKycAmlRuleFromBlock = 0;
function printBoundaryKycAmlRuleContractDetails() {
  if (boundaryKycAmlRuleFromBlock == 0) {
    boundaryKycAmlRuleFromBlock = baseBlock;
  }
  console.log("RESULT: boundaryKycAmlRule.address=" + getAddressName(boundaryKycAmlRuleContractAddress));
  if (boundaryKycAmlRuleContractAddress != null && boundaryKycAmlRuleContractAbi != null) {
    var contract = eth.contract(boundaryKycAmlRuleContractAbi).at(boundaryKycAmlRuleContractAddress);
    console.log("RESULT: boundaryKycAmlRule.addressControlStatus=" + getAddressName(contract.addressControlStatus()));
    console.log("RESULT: boundaryKycAmlRule.kycAmlStatus=" + getAddressName(contract.kycAmlStatus()));

    var latestBlock = eth.blockNumber;
    var i;

    // No events

    boundaryKycAmlRuleFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// FullKycAmlRule Contract
// -----------------------------------------------------------------------------
var fullKycAmlRuleContractAddress = null;
var fullKycAmlRuleContractAbi = null;

function addFullKycAmlRuleContractAddressAndAbi(address, abi) {
  fullKycAmlRuleContractAddress = address;
  fullKycAmlRuleContractAbi = abi;
}

var fullKycAmlRuleFromBlock = 0;
function printFullKycAmlRuleContractDetails() {
  if (fullKycAmlRuleFromBlock == 0) {
    fullKycAmlRuleFromBlock = baseBlock;
  }
  console.log("RESULT: fullKycAmlRule.address=" + getAddressName(fullKycAmlRuleContractAddress));
  if (fullKycAmlRuleContractAddress != null && fullKycAmlRuleContractAbi != null) {
    var contract = eth.contract(fullKycAmlRuleContractAbi).at(fullKycAmlRuleContractAddress);
    console.log("RESULT: fullKycAmlRule.addressControlStatus=" + getAddressName(contract.addressControlStatus()));
    console.log("RESULT: fullKycAmlRule.kycAmlStatus=" + getAddressName(contract.kycAmlStatus()));

    var latestBlock = eth.blockNumber;
    var i;

    fullKycAmlRuleFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// MembershipWithBoundaryKycAmlRule Contract
// -----------------------------------------------------------------------------
var membershipWithBoundaryKycAmlRuleContractAddress = null;
var membershipWithBoundaryKycAmlRuleContractAbi = null;

function addMembershipWithBoundaryKycAmlRuleContractAddressAndAbi(address, abi) {
  membershipWithBoundaryKycAmlRuleContractAddress = address;
  membershipWithBoundaryKycAmlRuleContractAbi = abi;
}

var membershipWithBoundaryKycAmlRuleFromBlock = 0;
function printMembershipWithBoundaryKycAmlRuleContractDetails() {
  if (membershipWithBoundaryKycAmlRuleFromBlock == 0) {
    membershipWithBoundaryKycAmlRuleFromBlock = baseBlock;
  }
  console.log("RESULT: membershipWithBoundaryKycAmlRule.address=" + getAddressName(membershipWithBoundaryKycAmlRuleContractAddress));
  if (membershipWithBoundaryKycAmlRuleContractAddress != null && membershipWithBoundaryKycAmlRuleContractAbi != null) {
    var contract = eth.contract(membershipWithBoundaryKycAmlRuleContractAbi).at(membershipWithBoundaryKycAmlRuleContractAddress);
    console.log("RESULT: membershipWithBoundaryKycAmlRule.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: membershipWithBoundaryKycAmlRule.owner=" + getAddressName(contract.owner()));
    console.log("RESULT: membershipWithBoundaryKycAmlRule.membershipAuthority=" + getAddressName(contract.membershipAuthority()));

    var latestBlock = eth.blockNumber;
    var i;

    var logSetAuthorityEvents = contract.LogSetAuthority({}, { fromBlock: membershipWithBoundaryKycAmlRuleFromBlock, toBlock: latestBlock });
    i = 0;
    logSetAuthorityEvents.watch(function (error, result) {
      console.log("RESULT: membershipWithBoundaryKycAmlRule.LogSetAuthority " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetAuthorityEvents.stopWatching();

    var logSetOwnerEvents = contract.LogSetOwner({}, { fromBlock: membershipWithBoundaryKycAmlRuleFromBlock, toBlock: latestBlock });
    i = 0;
    logSetOwnerEvents.watch(function (error, result) {
      console.log("RESULT: membershipWithBoundaryKycAmlRule.LogSetOwner " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetOwnerEvents.stopWatching();

    membershipWithBoundaryKycAmlRuleFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// LimitController Contract
// -----------------------------------------------------------------------------
var limitControllerContractAddress = null;
var limitControllerContractAbi = null;

function addLimitControllerContractAddressAndAbi(address, abi) {
  limitControllerContractAddress = address;
  limitControllerContractAbi = abi;
}

var limitControllerFromBlock = 0;
function printLimitControllerContractDetails() {
  if (limitControllerFromBlock == 0) {
    limitControllerFromBlock = baseBlock;
  }
  console.log("RESULT: limitController.address=" + getAddressName(limitControllerContractAddress));
  if (limitControllerContractAddress != null && limitControllerContractAbi != null) {
    var contract = eth.contract(limitControllerContractAbi).at(limitControllerContractAddress);
    console.log("RESULT: limitController.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: limitController.owner=" + getAddressName(contract.owner()));
    console.log("RESULT: limitController.stopped=" + contract.stopped());
    console.log("RESULT: limitController.mintLimitCounter=" + contract.mintLimitCounter());
    console.log("RESULT: limitController.burnLimitCounter=" + contract.burnLimitCounter());
    console.log("RESULT: limitController.lastLimitResetTime=" + contract.lastLimitResetTime() + " " + new Date(contract.lastLimitResetTime() * 1000).toUTCString());
    console.log("RESULT: limitController.limitSetting=" + getAddressName(contract.limitSetting()));

    var latestBlock = eth.blockNumber;
    var i;

    var logSetAuthorityEvents = contract.LogSetAuthority({}, { fromBlock: limitControllerFromBlock, toBlock: latestBlock });
    i = 0;
    logSetAuthorityEvents.watch(function (error, result) {
      console.log("RESULT: limitController.LogSetAuthority " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetAuthorityEvents.stopWatching();

    var logSetOwnerEvents = contract.LogSetOwner({}, { fromBlock: limitControllerFromBlock, toBlock: latestBlock });
    i = 0;
    logSetOwnerEvents.watch(function (error, result) {
      console.log("RESULT: limitController.LogSetOwner " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetOwnerEvents.stopWatching();

    var logNoteEvents = contract.LogNote({}, { fromBlock: limitControllerFromBlock, toBlock: latestBlock });
    i = 0;
    logNoteEvents.watch(function (error, result) {
      console.log("RESULT: limitController.LogNote " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logNoteEvents.stopWatching();

    limitControllerFromBlock = latestBlock + 1;
  }
}


// -----------------------------------------------------------------------------
// GateWithFee Contract
// -----------------------------------------------------------------------------
var gateWithFeeContractAddress = null;
var gateWithFeeContractAbi = null;

function addGateWithFeeContractAddressAndAbi(address, abi) {
  gateWithFeeContractAddress = address;
  gateWithFeeContractAbi = abi;
}

var gateWithFeeFromBlock = 0;
function printGateWithFeeContractDetails() {
  if (gateWithFeeFromBlock == 0) {
    gateWithFeeFromBlock = baseBlock;
  }
  console.log("RESULT: gateWithFee.address=" + getAddressName(gateWithFeeContractAddress));
  if (gateWithFeeContractAddress != null && gateWithFeeContractAbi != null) {
    var contract = eth.contract(gateWithFeeContractAbi).at(gateWithFeeContractAddress);
    console.log("RESULT: gateWithFee.authority=" + getAddressName(contract.authority()));
    console.log("RESULT: gateWithFee.owner=" + getAddressName(contract.owner()));
    console.log("RESULT: gateWithFee.limitController=" + getAddressName(contract.limitController()));
    console.log("RESULT: gateWithFee.mintFeeCollector=" + getAddressName(contract.mintFeeCollector()));
    console.log("RESULT: gateWithFee.burnFeeCollector=" + getAddressName(contract.burnFeeCollector()));
    console.log("RESULT: gateWithFee.transferFeeController=" + getAddressName(contract.transferFeeController()));
    console.log("RESULT: gateWithFee.stopped=" + contract.stopped());
    console.log("RESULT: gateWithFee.token=" + getAddressName(contract.token()));

    var latestBlock = eth.blockNumber;
    var i;

    var logSetAuthorityEvents = contract.LogSetAuthority({}, { fromBlock: gateWithFeeFromBlock, toBlock: latestBlock });
    i = 0;
    logSetAuthorityEvents.watch(function (error, result) {
      console.log("RESULT: gateWithFee.LogSetAuthority " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetAuthorityEvents.stopWatching();

    var logSetOwnerEvents = contract.LogSetOwner({}, { fromBlock: gateWithFeeFromBlock, toBlock: latestBlock });
    i = 0;
    logSetOwnerEvents.watch(function (error, result) {
      console.log("RESULT: gateWithFee.LogSetOwner " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetOwnerEvents.stopWatching();

    var logNoteEvents = contract.LogNote({}, { fromBlock: gateWithFeeFromBlock, toBlock: latestBlock });
    i = 0;
    logNoteEvents.watch(function (error, result) {
      console.log("RESULT: gateWithFee.LogNote " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logNoteEvents.stopWatching();

    var depositRequestedEvents = contract.DepositRequested({}, { fromBlock: gateWithFeeFromBlock, toBlock: latestBlock });
    i = 0;
    depositRequestedEvents.watch(function (error, result) {
      console.log("RESULT: gateWithFee.DepositRequested " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    depositRequestedEvents.stopWatching();

    var withdrawalRequestedEvents = contract.WithdrawalRequested({}, { fromBlock: gateWithFeeFromBlock, toBlock: latestBlock });
    i = 0;
    withdrawalRequestedEvents.watch(function (error, result) {
      console.log("RESULT: gateWithFee.WithdrawalRequested " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    withdrawalRequestedEvents.stopWatching();

    var withdrawnEvents = contract.Withdrawn({}, { fromBlock: gateWithFeeFromBlock, toBlock: latestBlock });
    i = 0;
    withdrawnEvents.watch(function (error, result) {
      console.log("RESULT: gateWithFee.Withdrawn " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    withdrawnEvents.stopWatching();

    var logSetLimitControllerEvents = contract.LogSetLimitController({}, { fromBlock: gateWithFeeFromBlock, toBlock: latestBlock });
    i = 0;
    logSetLimitControllerEvents.watch(function (error, result) {
      console.log("RESULT: gateWithFee.LogSetLimitController " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    logSetLimitControllerEvents.stopWatching();

    var approvalEvents = contract.Approval({}, { fromBlock: gateWithFeeFromBlock, toBlock: latestBlock });
    i = 0;
    approvalEvents.watch(function (error, result) {
      console.log("RESULT: gateWithFee.Approval " + i++ + " #" + result.blockNumber + " src=" + result.args.src +
        " guy=" + result.args.guy + " wad=" + result.args.wad.shift(-decimals));
    });
    approvalEvents.stopWatching();

    var transferEvents = contract.Transfer({}, { fromBlock: gateWithFeeFromBlock, toBlock: latestBlock });
    i = 0;
    transferEvents.watch(function (error, result) {
      console.log("RESULT: gateWithFee.Transfer " + i++ + " #" + result.blockNumber + ": src=" + result.args.src + " dst=" + result.args.dst +
        " wad=" + result.args.wad.shift(-decimals));
    });
    transferEvents.stopWatching();

    gateWithFeeFromBlock = latestBlock + 1;
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
function getListedOption() {
  if (dexWalletFactoryFromBlock == 0) {
    dexWalletFactoryFromBlock = baseBlock;
  }
  var options = [];
  console.log("RESULT: dexWalletFactoryContractAddress=" + dexWalletFactoryContractAddress);
  if (dexWalletFactoryContractAddress != null && dexWalletFactoryContractAbi != null) {
    var contract = eth.contract(dexWalletFactoryContractAbi).at(dexWalletFactoryContractAddress);

    var latestBlock = eth.blockNumber;
    var i;

    var optionListedEvents = contract.OptionListed({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    optionListedEvents.watch(function (error, result) {
      console.log("RESULT: get OptionListed " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
      options.push(result.args.optionAddress);
    });
    optionListedEvents.stopWatching();
  }
  return options;
}
function printDEXWalletFactoryContractDetails() {
  if (dexWalletFactoryFromBlock == 0) {
    dexWalletFactoryFromBlock = baseBlock;
  }
  console.log("RESULT: dexWalletFactory.address=" + dexWalletFactoryContractAddress);
  if (dexWalletFactoryContractAddress != null && dexWalletFactoryContractAbi != null) {
    var contract = eth.contract(dexWalletFactoryContractAbi).at(dexWalletFactoryContractAddress);
    console.log("RESULT: dexWalletFactory.owner/new=" + contract.owner() + " " + contract.newOwner());
    console.log("RESULT: dexWalletFactory.daiAddress=" + contract.daiAddress());
    console.log("RESULT: dexWalletFactory.pricefeed=" + contract.pricefeed());
    console.log("RESULT: dexWalletFactory.fee=" + contract.fee().shift(-18) + " ETH/ETH Nominal");
    console.log("RESULT: dexWalletFactory.maxTerm=" + contract.maxTerm() + " seconds " + contract.maxTerm()/60/60/24 + " days");
    console.log("RESULT: dexWalletFactory.DECIMALS=" + contract.DECIMALS());
    console.log("RESULT: dexWalletFactory.optionTemplate=" + contract.optionTemplate());
    console.log("RESULT: dexWalletFactory.optionTokenTemplate=" + contract.optionTokenTemplate());
    console.log("RESULT: dexWalletFactory.numberOfOptions=" + contract.numberOfOptions());

    var i;
    for (i = 0; i < contract.numberOfOptions(); i++) {
      var optionAddress = contract.options(i);
      var optionDetail = contract.optionDetails(optionAddress);
      console.log("RESULT: dexWalletFactory.optionDetails[" + i + "]=" + optionDetail);
    }

    var latestBlock = eth.blockNumber;

    var ownershipTransferredEvents = contract.OwnershipTransferred({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    ownershipTransferredEvents.watch(function (error, result) {
      console.log("RESULT: OwnershipTransferred " + i++ + " #" + result.blockNumber + " " + JSON.stringify(result.args));
    });
    ownershipTransferredEvents.stopWatching();

    var feeUpdatedEvents = contract.FeeUpdated({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    feeUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: FeeUpdated " + i++ + " #" + result.blockNumber + " oldFee=" + result.args.oldFee.shift(-18) +
        " newFee=" + result.args.newFee.shift(-18));
    });
    feeUpdatedEvents.stopWatching();

    var maxTermUpdatedEvents = contract.MaxTermUpdated({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    maxTermUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: MaxTermUpdated " + i++ + " #" + result.blockNumber + " oldTerm=" + result.args.oldTerm +
        " newTerm=" + result.args.newTerm);
    });
    maxTermUpdatedEvents.stopWatching();

    var minNominalUpdatedEvents = contract.MinNominalUpdated({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    minNominalUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: MinNominalUpdated " + i++ + " #" + result.blockNumber + " oldMinNominal=" + result.args.oldMinNominal +
        " newMinNominal=" + result.args.newMinNominal);
    });
    minNominalUpdatedEvents.stopWatching();

    var maxEntriesUpdatedEvents = contract.MaxEntriesUpdated({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    maxEntriesUpdatedEvents.watch(function (error, result) {
      console.log("RESULT: MaxEntriesUpdated " + i++ + " #" + result.blockNumber + " oldMaxEntries=" + result.args.oldMaxEntries +
        " newMaxEntries=" + result.args.newMaxEntries);
    });
    maxEntriesUpdatedEvents.stopWatching();

    var optionListedEvents = contract.OptionListed({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    optionListedEvents.watch(function (error, result) {
      console.log("RESULT: OptionListed " + i++ + " #" + result.blockNumber + " optionAddress=" + result.args.optionAddress +
        " owner=" + result.args.owner + " isCall=" + result.args.isCall + " expiry=" + new Date(result.args.expiry * 1000).toString() +
        " strike=" + result.args.strike.shift(-18) + " symbol=" + result.args.symbol + " name=" + result.args.name);
    });
    optionListedEvents.stopWatching();

    var feeReceivedEvents = contract.FeeReceived({}, { fromBlock: dexWalletFactoryFromBlock, toBlock: latestBlock });
    i = 0;
    feeReceivedEvents.watch(function (error, result) {
      console.log("RESULT: FeeReceived " + i++ + " #" + result.blockNumber + " sender=" + result.args.sender +
        " fee=" + result.args.fee.shift(-18));
    });
    feeReceivedEvents.stopWatching();

    dexWalletFactoryFromBlock = latestBlock + 1;
  }
}
