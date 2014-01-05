Param([string]$wallet)
If(!$wallet){$wallet = Read-Host "Please enter DOGE wallet address"}

$walletAPI = "http://dogechain.info/chain/CHAIN/q/addressbalance"
$cryptoAPI = "http://www.cryptocoincharts.info/v2/api/tradingPair"
$pairDOGEtoBTC = "DOGE_BTC"
$pairBTCtoUSD = "BTC_USD"

$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
$webclient = New-Object Net.Webclient
$webclient.proxy = $proxy

#Get num of DOGE in wallet
$balance = $webclient.DownloadString("$walletAPI/$wallet")

#Get current DOGE to BTC price
#DOGEtoBTC contains following properties: ID,price,price_before_24,volume_first,volume_second,volume_btc,best_market,latest_trade
$strDOGEtoBTC = $webclient.DownloadString("$cryptoAPI/$pairDOGEtoBTC")
$DOGEtoBTC = $strDOGEtoBTC | ConvertFrom-JSON

#Get current BTC to USD price
#Contains same properties as above object
$strBTCtoUSD = $webclient.DownloadString("$cryptoAPI/$pairBTCtoUSD")
$BTCtoUSD = $strBTCtoUSD | ConvertFrom-JSON

$BTCValue = [double]$balance * [double]$DOGEtoBTC.price
$USDvalue = [double]$BTCValue * [double]$BTCtoUSD.price
Write-Host "DOGECoin Wallet Address: $wallet"
Write-Host "Balance of Wallet: $balance"
Write-Host "Best Market Currently (DOGE\BTC): $($DOGEtoBTC.best_market)"
Write-Host "Balance of wallet in BTC: $BTCValue"
Write-Host "Best Market Currently (BTC\USD): $($BTCtoUSD.best_market)"
Write-Host "Balance of wallet in USD: $USDValue"