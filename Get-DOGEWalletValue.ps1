Param([string]$wallet)
If(!$wallet){$wallet = Read-Host "Please enter DOGE wallet address (Seperate with comma if multiple)"}

$walletAPI = "http://dogechain.info/chain/CHAIN/q/addressbalance"
$cryptoAPI = "http://www.cryptocoincharts.info/v2/api/tradingPair"
$pairDOGEtoBTC = "DOGE_BTC"
$pairBTCtoUSD = "BTC_USD"
$balance = 0

$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
$webclient = New-Object Net.Webclient
$webclient.proxy = $proxy

#Get num of DOGE in wallet(s)
$things = $wallet.Split(",")
Write-Host "Processing $($things.count) wallet(s)"
Foreach($w in $things)
{
    $wbalance = $webclient.DownloadString("$walletAPI/$w")
    $balance = [double]$balance + [double]$wbalance
}


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
$result = @{}
$result.Add("DOGE Wallet(s)", $wallet)
$result.Add("Wallet Balance",$balance)
$result.Add("Balance in BTC",$BTCValue)
$result.Add("Best market(DOGE to BTC)",$DOGEtoBTC.best_market)
$result.Add("Balance in USD",$USDValue)
$result.Add("Best market(BTC to USD)",$BTCtoUSD.best_market)
Write-Host "DOGECoin Wallet(s): $wallet"
Write-Host "Balance of Wallet: $balance"
Write-Host "Best Market Currently (DOGE\BTC): $($DOGEtoBTC.best_market)"
Write-Host "Balance of wallet in BTC: $BTCValue"
Write-Host "Best Market Currently (BTC\USD): $($BTCtoUSD.best_market)"
Write-Host "Balance of wallet in USD: $USDValue"
#Write-Host "`n--------------`n"
#$result | ft