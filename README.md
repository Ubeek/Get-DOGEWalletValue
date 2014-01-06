Get-DOGEWalletValue
===================

Please donate DOGE to D6p7Zu7EDy5hrZKxF5VE6onTtPbx5AuH2u if you find this useful! :D

Overview
--------
Gets the value of a DOGECoin wallets address in BTC and USD, detailing the best market for each trade. 
Accepts 1 or more wallet addresses seperated by comma.


Requirements
--------
Powershell v3


Usage
-------
Running the script without any arguments will prompt for all required information.

Get-DOGEWalletValue will also accept the following parameters:
-wallet <WALLETSTRING> 
Sets the wallet address instead of prompting for it at runtime.
eg:   -wallet D6p7Zu7EDy5hrZKxF5VE6onTtPbx5AuH2u
      -wallet D6p7Zu7EDy5hrZKxF5VE6onTtPbx5AuH2u,AnotherWalletAddress,YetAnotherWalletAddress
      
-log <Y/N>    (Default value is Y)
Turns on/off the CSV logging feature (Writes to walletaddress.csv in current working dir)
eg:   -log y
      -log n
      
-useStoredWallet <Y/N>    (Default value is N)
Sets the wallet address from the stored data instead of prompting for it
eg:   -useStoredWallet y
