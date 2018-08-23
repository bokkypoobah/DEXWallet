# DEXWallet
Decentralised Exchange Wallet


GNT/ETH = 0.00054087

1 GNT = 0.00054087 ETH

buy GNT / sell ETH

sell GNT / buy ETH

baseToken = GNT
quoteToken = ETH
price = #quoteToken per unit baseToken

// GNT/ETH = base/quote = 0.00054087
struct Order {
    OrderType orderType;
    address baseToken;      // GNT
    address quoteToken;     // ETH
    uint price;             // GNT/ETH = 0.00054087 = #quoteToken per unit baseToken
    uint expiry;
    uint amount;
    uint index;
}
