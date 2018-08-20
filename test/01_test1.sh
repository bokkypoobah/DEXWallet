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
var tokenASymbol = "TOKA";
var tokenAName = "Token A";
var tokenADecimals = 18;
var tokenAInitialSupply = 0;
var tokenBSymbol = "TOKB";
var tokenBName = "Token B";
var tokenBDecimals = 18;
var tokenBInitialSupply = 0;
// -----------------------------------------------------------------------------
console.log("RESULT: ---------- " + deployGroup1Message + " ----------");
var dexWalletFactoryContract = web3.eth.contract(dexWalletFactoryAbi);
var dexWalletFactoryTx = null;
var dexWalletFactoryAddress = null;
var dexWalletFactory = dexWalletFactoryContract.new({from: deployer, data: dexWalletFactoryBin, gas: 2000000, gasPrice: defaultGasPrice},
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
console.log("RESULT: ----- " + deployWallets1Message + " -----");
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
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var distributedTokensMessage = "Distribute Tokens #1";
var tokenAAmount = new BigNumber("1000").shift(tokenADecimals);
var tokenBAmount = new BigNumber("10000").shift(tokenBDecimals);
// -----------------------------------------------------------------------------
console.log("RESULT: ----- " + distributedTokensMessage + " -----");
var distributedTokens_1Tx = tokenA.mint(user1WalletAddress, tokenAAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributedTokens_2Tx = tokenA.mint(user2WalletAddress, tokenAAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributedTokens_3Tx = tokenA.mint(user3WalletAddress, tokenAAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributedTokens_4Tx = tokenB.mint(user1WalletAddress, tokenBAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributedTokens_5Tx = tokenB.mint(user2WalletAddress, tokenBAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
var distributedTokens_6Tx = tokenB.mint(user3WalletAddress, tokenBAmount, {from: deployer, gas: 2000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(distributedTokens_1Tx, distributedTokensMessage + " - tokenA.mint(user1Wallet, " + tokenAAmount.shift(-tokenADecimals) + ")");
failIfTxStatusError(distributedTokens_2Tx, distributedTokensMessage + " - tokenA.mint(user2Wallet, " + tokenAAmount.shift(-tokenADecimals) + ")");
failIfTxStatusError(distributedTokens_3Tx, distributedTokensMessage + " - tokenA.mint(user3Wallet, " + tokenAAmount.shift(-tokenADecimals) + ")");
failIfTxStatusError(distributedTokens_4Tx, distributedTokensMessage + " - tokenB.mint(user1Wallet, " + tokenBAmount.shift(-tokenBDecimals) + ")");
failIfTxStatusError(distributedTokens_5Tx, distributedTokensMessage + " - tokenB.mint(user2Wallet, " + tokenBAmount.shift(-tokenBDecimals) + ")");
failIfTxStatusError(distributedTokens_6Tx, distributedTokensMessage + " - tokenB.mint(user3Wallet, " + tokenBAmount.shift(-tokenBDecimals) + ")");
printTxData("distributedTokens_1Tx", distributedTokens_1Tx);
printTxData("distributedTokens_2Tx", distributedTokens_2Tx);
printTxData("distributedTokens_3Tx", distributedTokens_3Tx);
printTxData("distributedTokens_4Tx", distributedTokens_4Tx);
printTxData("distributedTokens_5Tx", distributedTokens_5Tx);
printTxData("distributedTokens_6Tx", distributedTokens_6Tx);
printTokenAContractDetails();
printTokenBContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
