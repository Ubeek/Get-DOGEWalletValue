Param([string]$wallet)
$pathWallet = "wallet.txt"
If(Test-Path $pathWallet)
{
    If($(Read-Host "Use stored wallet address(es)? (y/n)") -ilike "y*")
    {
        $wallet = Get-Content $pathWallet        
    }
}
If(!$wallet)
{
    $wallet = Read-Host "Please enter DOGE wallet address (Seperate with comma if multiple)"
    If($(Read-Host "Would you like to store this address for future use? (y/n)`nWarning: Overwrites previously stored addresses") -ilike "y*")
    {
        If(Test-Path $pathWallet){Remove-Item $pathWallet}
        Add-Content $pathWallet $wallet
    }
}

$walletAPI = "http://dogechain.info/chain/CHAIN/q/addressbalance"
$cryptoAPI = "http://www.cryptocoincharts.info/v2/api/tradingPair"
$pairDOGEtoBTC = "DOGE_BTC"
$pairBTCtoUSD = "BTC_USD"
$balance = 0

$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
$webclient = New-Object Net.Webclient
$webclient.proxy = $proxy

$things = $wallet.Split(",")
$things = $things.Replace(" ","")

Foreach($w in $things) #Get num of DOGE in wallet(s)
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

Write-Host "-------`nResults`n-------" -ForegroundColor Green
Write-Host "DOGECoin Wallet(s): `t`t`t$wallet"
Write-Host "Balance of Wallet: `t`t`t$balance DOGE"
Write-Host "Best Market Currently (DOGE\BTC): `t$($DOGEtoBTC.best_market)"
Write-Host "Balance of wallet in BTC: `t`t$BTCValue"
Write-Host "Best Market Currently (BTC\USD): `t$($BTCtoUSD.best_market)"
Write-Host "Balance of wallet in USD:`t`t`$$USDValue"