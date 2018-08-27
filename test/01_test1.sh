#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

source settings
echo "---------- Settings ----------" | tee $TEST1OUTPUT
cat ./settings | tee -a $TEST1OUTPUT
echo "" | tee -a $TEST1OUTPUT

CURRENTTIME=`date +%s`
CURRENTTIMES=`perl -le "print scalar localtime $CURRENTTIME"`
START_DATE=`echo "$CURRENTTIME+45" | bc`
START_DATE_S=`perl -le "print scalar localtime $START_DATE"`
END_DATE=`echo "$CURRENTTIME+60*2" | bc`
END_DATE_S=`perl -le "print scalar localtime $END_DATE"`

printf "CURRENTTIME               = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "START_DATE                = '$START_DATE' '$START_DATE_S'\n" | tee -a $TEST1OUTPUT
printf "END_DATE                  = '$END_DATE' '$END_DATE_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file ---
# rsync -rp $SOURCEDIR/* . --exclude=Multisig.sol --exclude=test/
rsync -rp $SOURCEDIR/* . --exclude=Multisig.sol
# Copy modified contracts if any files exist
find ./modifiedContracts -type f -name \* -exec cp {} . \;

# --- Modify parameters ---
#`perl -pi -e "s/AddressControlStatus addressControlStatus;/AddressControlStatus public addressControlStatus;/" Kyc.sol`

DIFFS1=`diff -r -x '*.js' -x '*.json' -x '*.txt' -x 'testchain' -x '*.md' -x '*.sh' -x 'settings' -x 'modifiedContracts' $SOURCEDIR .`
echo "--- Differences $SOURCEDIR/*.sol *.sol ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT


solc_0.4.24 --version | tee -a $TEST1OUTPUT

echo "var dexWalletOutput=`solc_0.4.24 --allow-paths . --optimize --pretty-json --combined-json abi,bin,interface $DEXWALLETSOL`;" > $DEXWALLETJS
echo "var mintableTokenOutput=`solc_0.4.24 --allow-paths . --optimize --pretty-json --combined-json abi,bin,interface $MINTABLETOKENSOL`;" > $MINTABLETOKENJS


geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$DEXWALLETJS");
loadScript("$MINTABLETOKENJS");
loadScript("lookups.js");
loadScript("functions.js");

var dexWalletAbi = JSON.parse(dexWalletOutput.contracts["$DEXWALLETSOL:DEXWallet"].abi);
var dexWalletFactoryAbi = JSON.parse(dexWalletOutput.contracts["$DEXWALLETSOL:DEXWalletFactory"].abi);
var dexWalletFactoryBin = "0x" + dexWalletOutput.contracts["$DEXWALLETSOL:DEXWalletFactory"].bin;
var mintableTokenAbi = JSON.parse(mintableTokenOutput.contracts["$MINTABLETOKENSOL:MintableToken"].abi);
var mintableTokenBin = "0x" + mintableTokenOutput.contracts["$MINTABLETOKENSOL:MintableToken"].bin;

// console.log("DATA: dexWalletAbi=" + JSON.stringify(dexWalletAbi));
// console.log("DATA: dexWalletFactoryAbi=" + JSON.stringify(dexWalletFactoryAbi));
// console.log("DATA: dexWalletFactoryBin=" + JSON.stringify(dexWalletFactoryBin));
// console.log("DATA: mintableTokenAbi=" + JSON.stringify(mintableTokenAbi));
// console.log("DATA: mintableTokenBin=" + JSON.stringify(mintableTokenBin));


unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployGroup1Message = "Deploy Group #1";
var tokenASymbol = "GNT";
var tokenAName = "Golem";
var tokenADecimals = 18;
var tokenAInitialSupply = 0;
var tokenBSymbol = "WETH";
var tokenBName = "Wrapped ETH";
var tokenBDecimals = 18;
var tokenBInitialSupply = 0;
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployGroup1Message + " ----------");
var dexWalletFactoryContract = web3.eth.contract(dexWalletFactoryAbi);
var dexWalletFactoryTx = null;
var dexWalletFactoryAddress = null;
var dexWalletFactory = dexWalletFactoryContract.new({from: deployer, data: dexWalletFactoryBin, gas: 5000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        dexWalletFactoryTx = contract.transactionHash;
      } else {
        dexWalletFactoryAddress = contract.address;
        addAccount(dexWalletFactoryAddress, "DEXWalletFactory");
        addDEXWalletFactoryContractAddressAndAbi(dexWalletFactoryAddress, dexWalletFactoryAbi);
        console.log("DATA: var dexWalletFactoryAddress=\"" + dexWalletFactoryAddress + "\";");
        console.log("DATA: var dexWalletFactoryAbi=" + JSON.stringify(dexWalletFactoryAbi) + ";");
        console.log("DATA: var dexWalletFactory=eth.contract(dexWalletFactoryAbi).at(dexWalletFactoryAddress);");
      }
    }
  }
);
var tokenAContract = web3.eth.contract(mintableTokenAbi);
var tokenATx = null;
var tokenAAddress = null;
var tokenA = tokenAContract.new(tokenASymbol, tokenAName, tokenADecimals, deployer, tokenAInitialSupply, {from: deployer, data: mintableTokenBin, gas: 2000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenATx = contract.transactionHash;
      } else {
        tokenAAddress = contract.address;
        addAccount(tokenAAddress, "Token '" + tokenA.symbol() + "' '" + tokenA.name() + "'");
        addAddressSymbol(tokenAAddress, tokenA.symbol());
        addTokenAContractAddressAndAbi(tokenAAddress, mintableTokenAbi);
        console.log("DATA: var tokenAAddress=\"" + tokenAAddress + "\";");
        console.log("DATA: var tokenAAbi=" + JSON.stringify(mintableTokenAbi) + ";");
        console.log("DATA: var tokenA=eth.contract(tokenAAbi).at(tokenAAddress);");
      }
    }
  }
);
var tokenBContract = web3.eth.contract(mintableTokenAbi);
var tokenBTx = null;
var tokenBAddress = null;
var tokenB = tokenBContract.new(tokenBSymbol, tokenBName, tokenBDecimals, deployer, tokenBInitialSupply, {from: deployer, data: mintableTokenBin, gas: 2000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenBTx = contract.transactionHash;
      } else {
        tokenBAddress = contract.address;
        addAccount(tokenBAddress, "Token '" + tokenB.symbol() + "' '" + tokenB.name() + "'");
        addAddressSymbol(tokenBAddress, tokenB.symbol());
        addTokenBContractAddressAndAbi(tokenBAddress, mintableTokenAbi);
        console.log("DATA: var tokenBAddress=\"" + tokenBAddress + "\";");
        console.log("DATA: var tokenBAbi=" + JSON.stringify(mintableTokenAbi) + ";");
        console.log("DATA: var tokenB=eth.contract(tokenBAbi).at(tokenBAddress);");
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(dexWalletFactoryTx, deployGroup1Message + " - DEXWalletFactory");
failIfTxStatusError(tokenATx, deployGroup1Message + " - Token ''" + tokenA.symbol() + "' '" + tokenA.name() + "'");
failIfTxStatusError(tokenBTx, deployGroup1Message + " - Token ''" + tokenB.symbol() + "' '" + tokenB.name() + "'");
printTxData("dexWalletFactoryTx", dexWalletFactoryTx);
printTxData("tokenATx", tokenATx);
printTxData("tokenBTx", tokenBTx);
printDEXWalletFactoryContractDetails();
printTokenAContractDetails();
printTokenBContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployWallets1Message = "Deploy Wallets #1";
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployWallets1Message + " ----------");
var deployWallets1_1Tx = dexWalletFactory.newDEXWallet({from: user1, gas: 2000000, gasPrice: defaultGasPrice});
var deployWallets1_2Tx = dexWalletFactory.newDEXWallet({from: user2, gas: 2000000, gasPrice: defaultGasPrice});
var deployWallets1_3Tx = dexWalletFactory.newDEXWallet({from: user3, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var newWallets = getNewDEXWallet();
console.log("RESULT: newWallets=" + JSON.stringify(newWallets));
var user1WalletAddress = newWallets[user1];
var user2WalletAddress = newWallets[user2];
var user3WalletAddress = newWallets[user3];
var user1Wallet = eth.contract(dexWalletAbi).at(user1WalletAddress);
var user2Wallet = eth.contract(dexWalletAbi).at(user2WalletAddress);
var user3Wallet = eth.contract(dexWalletAbi).at(user3WalletAddress);
console.log("DATA: var user1WalletAddress=\"" + user1WalletAddress + "\";");
console.log("DATA: var user2WalletAddress=\"" + user2WalletAddress + "\";");
console.log("DATA: var user3WalletAddress=\"" + user3WalletAddress + "\";");
console.log("DATA: var dexWalletAbi=" + JSON.stringify(dexWalletAbi) + ";");
console.log("DATA: var user1Wallet=eth.contract(dexWalletAbi).at(user1WalletAddress);");
console.log("DATA: var user2Wallet=eth.contract(dexWalletAbi).at(user2WalletAddress);");
console.log("DATA: var user3Wallet=eth.contract(dexWalletAbi).at(user3WalletAddress);");
addAccount(user1WalletAddress, "User1 DEXWallet");
addAccount(user2WalletAddress, "User2 DEXWallet");
addAccount(user3WalletAddress, "User3 DEXWallet");
printBalances();
failIfTxStatusError(deployWallets1_1Tx, deployWallets1Message + " - user1 newDEXWallet");
failIfTxStatusError(deployWallets1_2Tx, deployWallets1Message + " - user2 newDEXWallet");
failIfTxStatusError(deployWallets1_3Tx, deployWallets1Message + " - user3 newDEXWallet");
printTxData("deployWallets1_1Tx", deployWallets1_1Tx);
printTxData("deployWallets1_2Tx", deployWallets1_2Tx);
printTxData("deployWallets1_3Tx", deployWallets1_3Tx);
printDEXWalletFactoryContractDetails();
printDEXWalletContractDetails(user1WalletAddress, dexWalletAbi);
printDEXWalletContractDetails(user2WalletAddress, dexWalletAbi);
printDEXWalletContractDetails(user3WalletAddress, dexWalletAbi);
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var distributeTokensMessage = "Distribute Tokens #1";
var tokenAAmount = new BigNumber("1000").shift(tokenADecimals);
var tokenBAmount = new BigNumber("10").shift(tokenBDecimals);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + distributeTokensMessage + " ----------");
var distributeTokens_1Tx = tokenA.mint(user1WalletAddress, tokenAAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributeTokens_2Tx = tokenA.mint(user2WalletAddress, tokenAAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributeTokens_3Tx = tokenA.mint(user3WalletAddress, tokenAAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributeTokens_4Tx = tokenA.mint(account6, tokenAAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributeTokens_5Tx = tokenA.mint(account7, tokenAAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributeTokens_6Tx = tokenB.mint(user1WalletAddress, tokenBAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributeTokens_7Tx = tokenB.mint(user2WalletAddress, tokenBAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributeTokens_8Tx = tokenB.mint(user3WalletAddress, tokenBAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributeTokens_9Tx = tokenB.mint(account6, tokenBAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributeTokens_10Tx = tokenB.mint(account7, tokenBAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(distributeTokens_1Tx, distributeTokensMessage + " - tokenA.mint(user1Wallet, " + tokenAAmount.shift(-tokenADecimals) + ")");
failIfTxStatusError(distributeTokens_2Tx, distributeTokensMessage + " - tokenA.mint(user2Wallet, " + tokenAAmount.shift(-tokenADecimals) + ")");
failIfTxStatusError(distributeTokens_3Tx, distributeTokensMessage + " - tokenA.mint(user3Wallet, " + tokenAAmount.shift(-tokenADecimals) + ")");
failIfTxStatusError(distributeTokens_4Tx, distributeTokensMessage + " - tokenA.mint(account6, " + tokenAAmount.shift(-tokenADecimals) + ")");
failIfTxStatusError(distributeTokens_5Tx, distributeTokensMessage + " - tokenA.mint(account7, " + tokenAAmount.shift(-tokenADecimals) + ")");
failIfTxStatusError(distributeTokens_6Tx, distributeTokensMessage + " - tokenB.mint(user1Wallet, " + tokenBAmount.shift(-tokenBDecimals) + ")");
failIfTxStatusError(distributeTokens_7Tx, distributeTokensMessage + " - tokenB.mint(user2Wallet, " + tokenBAmount.shift(-tokenBDecimals) + ")");
failIfTxStatusError(distributeTokens_8Tx, distributeTokensMessage + " - tokenB.mint(user3Wallet, " + tokenBAmount.shift(-tokenBDecimals) + ")");
failIfTxStatusError(distributeTokens_9Tx, distributeTokensMessage + " - tokenB.mint(account6, " + tokenBAmount.shift(-tokenBDecimals) + ")");
failIfTxStatusError(distributeTokens_10Tx, distributeTokensMessage + " - tokenB.mint(account7, " + tokenBAmount.shift(-tokenBDecimals) + ")");
printTxData("distributeTokens_1Tx", distributeTokens_1Tx);
printTxData("distributeTokens_2Tx", distributeTokens_2Tx);
printTxData("distributeTokens_3Tx", distributeTokens_3Tx);
printTxData("distributeTokens_4Tx", distributeTokens_4Tx);
printTxData("distributeTokens_5Tx", distributeTokens_5Tx);
printTxData("distributeTokens_6Tx", distributeTokens_6Tx);
printTxData("distributeTokens_7Tx", distributeTokens_7Tx);
printTxData("distributeTokens_8Tx", distributeTokens_8Tx);
printTxData("distributeTokens_9Tx", distributeTokens_9Tx);
printTxData("distributeTokens_10Tx", distributeTokens_10Tx);
printTokenAContractDetails();
printTokenBContractDetails();
console.log("RESULT: ");


var BUY = 0;
var SELL = 1;

// -----------------------------------------------------------------------------
var addOrders1Message = "Add Orders #1";
var buyPrice = new BigNumber(0.00054087).shift(18);
var sellPrice = new BigNumber(0.00053087).shift(18);
var buyAmount = new BigNumber("1234.00").shift(18);
var sellAmount = new BigNumber("1234.00").shift(18);
var expiry = parseInt(new Date()/1000) + 60*60;
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + addOrders1Message + " ----------");
var addOrders1_1Tx = user1Wallet.addOrder(BUY, tokenAAddress, tokenBAddress, buyPrice, expiry, buyAmount, {from: user1, gas: 2000000, gasPrice: defaultGasPrice});
var addOrders1_2Tx = user2Wallet.addOrder(SELL, tokenAAddress, tokenBAddress, sellPrice, expiry, sellAmount, {from: user2, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(addOrders1_1Tx, addOrders1Message + " - user1Wallet.addOrder(BUY, " + tokenA.symbol() + ", " + tokenB.symbol() + ", " + buyPrice.shift(-18) + ", +1h, " + buyAmount.shift(-18) + ")");
failIfTxStatusError(addOrders1_2Tx, addOrders1Message + " - user2Wallet.addOrder(SELL, " + tokenA.symbol() + ", " + tokenB.symbol() + ", " + sellPrice.shift(-18) + ", +1h, " + sellAmount.shift(-18) + ")");
printTxData("addOrders1_1Tx", addOrders1_1Tx);
printTxData("addOrders1_2Tx", addOrders1_2Tx);
printDEXWalletContractDetails(user1WalletAddress, dexWalletAbi);
console.log("RESULT: ");


if (true) {
// -----------------------------------------------------------------------------
var takerSell1Message = "Taker Sell #1";
var sellAmount = new BigNumber(1000).shift(18);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + takerSell1Message + " ----------");
var takerSell1_1Tx = tokenA.approve(user1WalletAddress, sellAmount, {from: account6, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var orderKey = user1Wallet.getOrderKeyByIndex(user1Wallet.getNumberOfOrders() - 1);
var takerSell1_2Tx = user1Wallet.takerSell(orderKey, sellAmount, {from: account6, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(takerSell1_1Tx, takerSell1Message + " - ac6 tokenA.approve(user1WalletAddress, " + sellAmount.shift(-18) + ")");
failIfTxStatusError(takerSell1_2Tx, takerSell1Message + " - ac6 user1Wallet.takerSell(" + orderKey + ", " + sellAmount.shift(-18) + ")");
printTxData("takerSell1_1Tx", takerSell1_1Tx);
printTxData("takerSell1_2Tx", takerSell1_2Tx);
printDEXWalletContractDetails(user1WalletAddress, dexWalletAbi);
printTokenAContractDetails();
printTokenBContractDetails();
console.log("RESULT: ");
}


// -----------------------------------------------------------------------------
var takerBuy1Message = "Taker Buy #1";
var buyAmount = new BigNumber(1000).shift(18);
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + takerBuy1Message + " ----------");
var takerBuy1_1Tx = tokenB.approve(user2WalletAddress, buyAmount, {from: account7, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var orderKey = user2Wallet.getOrderKeyByIndex(user2Wallet.getNumberOfOrders() - 1);
var takerBuy1_2Tx = user2Wallet.takerBuy(orderKey, buyAmount, {from: account7, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(takerBuy1_1Tx, takerBuy1Message + " - ac7 tokenB.approve(user1WalletAddress, " + buyAmount.shift(-18) + ")");
failIfTxStatusError(takerBuy1_2Tx, takerBuy1Message + " - ac7 user2Wallet.takerBuy(" + orderKey + ", " + buyAmount.shift(-18) + ")");
printTxData("takerBuy1_1Tx", takerBuy1_1Tx);
printTxData("takerBuy1_2Tx", takerBuy1_2Tx);
printDEXWalletContractDetails(user2WalletAddress, dexWalletAbi);
printTokenAContractDetails();
printTokenBContractDetails();
console.log("RESULT: ");


exit;


if (false) {
// -----------------------------------------------------------------------------
var addOrders1Message = "Add Orders #1";
var price = new BigNumber(54087).shift(10); // 0.00054087 = new BigNumber(54087).shift(10);
var amount = new BigNumber("1234").shift(18);
var expiry = parseInt(new Date()/1000) + 60*60;
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + addOrders1Message + " ----------");
var addOrders1_1Tx = user1Wallet.addOrder(BUY, tokenAAddress, tokenBAddress, price, expiry, amount, {from: user1, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(addOrders1_1Tx, addOrders1Message + " - user1Wallet.addOrder(BUY, " + tokenA.symbol() + ", " + tokenB.symbol() + ", " + price.shift(-18) + ", +1h, " + amount.shift(-18) + ")");
printTxData("addOrders1_1Tx", addOrders1_1Tx);
printDEXWalletContractDetails(user1WalletAddress, dexWalletAbi);
console.log("RESULT: ");
}


if (false) {
// -----------------------------------------------------------------------------
var testOrders1 = "Test Orders #1";
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + testOrders1 + " ----------");
var orderKey = user1Wallet.getOrderKeyByIndex(user1Wallet.getNumberOfOrders() - 1);
var order = user1Wallet.getOrderByKey(orderKey);
var buyToken = tokenAAddress;
var sellToken = tokenBAddress;
var buyTokenSymbol = getAddressSymbol(buyToken);
var sellTokenSymbol = getAddressSymbol(sellToken);
console.log("RESULT: order=" + formatOrder(order[0], order[1], order[2], order[3], order[4], order[5], order[6]));
[new BigNumber(0).shift(18), new BigNumber(10).shift(18), new BigNumber(100).shift(18), new BigNumber(1000).shift(18), new BigNumber(10000).shift(18), new BigNumber(100000).shift(18)].forEach(function(buyTokens) {
  var details = user1Wallet.getWalletBuyingDetails(orderKey, buyToken, sellToken, buyTokens);
  console.log("RESULT: buyTokens=" + buyTokens.shift(-18));
  console.log("RESULT:   _buyTokens=" + details[0].shift(-18) + " " + buyTokenSymbol);
  console.log("RESULT:   _sellTokens=" + details[1].shift(-18) + " " + sellTokenSymbol);
  console.log("RESULT:   _price=" + details[2].shift(-18) + " " + (details[3] == true ? "Inverse" : ""));
});
console.log("RESULT: ");
}


if (false) {
// -----------------------------------------------------------------------------
var addOrders2Message = "Add Orders #2";
// GNT/ETH 0.00055087 = ETH/GNT 1815.310327300452012
var price = new BigNumber("1815.310327300452012").shift(18);
var amount = new BigNumber("10").shift(18);
var expiry = parseInt(new Date()/1000) + 60*60;
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + addOrders2Message + " ----------");
var addOrders2_1Tx = user1Wallet.addOrder(SELL, tokenBAddress, tokenAAddress, price, expiry, amount, {from: user1, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(addOrders2_1Tx, addOrders2Message + " - user1Wallet.addOrder(SELL, " + tokenB.symbol() + ", " + tokenA.symbol() + ", " + price.shift(-18) + ", +1h, " + amount.shift(-18) + ")");
printTxData("addOrders2_1Tx", addOrders2_1Tx);
printDEXWalletContractDetails(user1WalletAddress, dexWalletAbi);
console.log("RESULT: ");
}


if (false) {
// -----------------------------------------------------------------------------
var testOrders2 = "Test Orders #1";
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + testOrders2 + " ----------");
var orderKey = user1Wallet.getOrderKeyByIndex(user1Wallet.getNumberOfOrders() - 1);
var order = user1Wallet.getOrderByKey(orderKey);
var buyToken = tokenAAddress;
var sellToken = tokenBAddress;
var buyTokenSymbol = getAddressSymbol(buyToken);
var sellTokenSymbol = getAddressSymbol(sellToken);
console.log("RESULT: order=" + formatOrder(order[0], order[1], order[2], order[3], order[4], order[5], order[6]));
[new BigNumber(0).shift(18), new BigNumber(10).shift(18), new BigNumber(100).shift(18), new BigNumber(1000).shift(18), new BigNumber(10000).shift(18), new BigNumber(100000).shift(18)].forEach(function(buyTokens) {
  var details = user1Wallet.getWalletBuyingDetails(orderKey, buyToken, sellToken, buyTokens);
  console.log("RESULT: buyTokens=" + buyTokens.shift(-18));
  console.log("RESULT:   _buyTokens=" + details[0].shift(-18) + " " + buyTokenSymbol);
  console.log("RESULT:   _sellTokens=" + details[1].shift(-18) + " " + sellTokenSymbol);
  console.log("RESULT:   _price=" + details[2].shift(-18) + " " + (details[3] == true ? "Inverse" : ""));
});
console.log("RESULT: ");
}



EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
