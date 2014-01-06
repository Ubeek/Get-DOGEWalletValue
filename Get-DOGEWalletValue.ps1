Param([string]$wallet,[string]$log,[string]$useStoredWallet,[string]$logtype = "csv")
function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

#MySQL Logging settings - Note: This requires the Something Something NET Connector Thingy
$MySQLAdminUserName = 'root'
$MySQLAdminPassword = ''
$MySQLDatabase = 'Coin'
$MySQLHost = 'localhost'
$MySQLTable = 'pricing'

#This seems to barf with scheduled tasks, suggest replacing 'Get-ScriptDirectory' with actual path to script (or seperate data folder if you are that way inclined) when scheduling.
$pathScript = Get-ScriptDirectory

$pathWallet = "$pathScript\wallet.txt"
If($useStoredWallet -ilike "y*"){$wallet = Get-Content $pathWallet}
If((Test-Path $pathWallet) -and (!$wallet))
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

$pathLogCSV = "$pathScript\$wallet.csv"
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


If($log -ilike "y*")
{
    If($logtype -ilike "csv")
    {
        If(!$(Test-Path $pathLogCSV))
        {
            $CSVheader = "DateTime,Balance(DOGE),Value(BTC),TradePrice(DOGE-BTC),Market(DOGE-BTC),Value(USD),TradePrice(USD-BTC),Market(USD-BTC)"
            Add-Content $pathLogCSV $CSVheader
        }
        $currentDateTime = get-Date -format s
        Add-Content $pathLogCSV "$currentDateTime,$balance,$BTCValue,$($DOGEtoBTC.Price),$($DOGEtoBTC.best_market),$USDValue,$($BTCtoUSD.Price),$($BTCtoUSD.best_market)"
    }
    ElseIf($logtype -ilike "mysql")
    {
        $ConnectionString = "server=" + $MySQLHost + ";port=3306;uid=" + $MySQLAdminUserName + ";pwd=" + $MySQLAdminPassword + ";database="+$MySQLDatabase
        $currentDateTime = get-Date -format s
        $currentDateTime = $currentDateTime.Replace("T"," ")
        $query = "INSERT INTO ``$MySQLTable`` (``time``, ``wallet``, ``balance``, ``btcvalue``, ``btcprice``, ``btcmarket``, ``usdvalue``, ``usdprice``, ``usdmarket``) VALUES (""$currentDateTime"", ""$wallet"", $balance, $BTCValue, $($DOGEtoBTC.Price), ""$($DOGEtoBTC.best_market)"", $USDValue, $($BTCtoUSD.Price), ""$($BTCtoUSD.best_market)"")"
        Try
        {
            [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
            $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
            $Connection.ConnectionString = $ConnectionString
            $Connection.Open()
            $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
            $DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
            $DataSet = New-Object System.Data.DataSet
            $RecordCount = $dataAdapter.Fill($dataSet, "data")
        }
        Catch
        {
            Write-Host "ERROR : Unable to log data : $query `n$Error[0]"
        }
        Finally
        {
            $Connection.Close()
        }
    }
}