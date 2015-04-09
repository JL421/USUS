<#
.SYNOPSIS
	Downloads Update packages from specified sources, and updates the Software Repository.
.NOTES
	File Name	: USUS.ps1
	Author		: reddit.com/u/JL421
	Last Update : 2015-04-08
.EXAMPLE
	USUS.ps1 -SoftwareRepo "D:\Data\SoftwareRepo" -PackageRepo "D:\Data\Packages" -LogLocation "D:\Data\USUSLogs"
#>

param([Parameter(Mandatory=$True)][string]$SoftwareRepo,[Parameter(Mandatory=$True)][string]$PackageRepo,[string]$LogLocation)

# Define the WebClient

$WebClient = New-Object System.Net.WebClient

#Define Functions

function CheckUpdates
{
	ForEach ($i in $Updates)
	{
		IF ($i[0] -eq $False -And $i[1] -eq $False -And $i[2] -eq $False -And $i[3] -eq $False -And $i[4] -eq $False -And $i[5] -eq $False -And $i[6] -eq $False -And $i[7] -eq $False)
		{
			return
		}
		
		$LocalRepo = $i[5]
		
		IF (!(Test-Path $LocalRepo))
		{
			CLS
			Write-Host "Software Repository $LocalRepo dosen't seem to exist.
Please create this location or run this script with the credentials required to access it."
			Exit
		}
		$tempdownloadlocation = $env:TEMP
		$ProgramName = $i[2]
		$url = $i[6]
		
		IF ($i[0] -eq $True)
		{
			$LocalRepo = $i[5] + "\DefaultPrograms"
			IF (!(Test-Path $LocalRepo))
			{
				Try
				{
					New-Item $LocalRepo -Type Directory -ErrorAction Stop | Out-Null
				} Catch {
					Write-Host "`r`nCould not create program directory of $LocalRepo.
Please ensure that this script has Write permissions to this location, and try again."
				} 
			}
		}
		
		$LocalRepo = $LocalRepo + "\" + $i[1]
		IF (!(Test-Path $LocalRepo))
		{
			Try
			{
				New-Item $LocalRepo -Type Directory -ErrorAction Stop | Out-Null
			} Catch {
				Write-Host "`r`nCould not create program directory of $LocalRepo.
Please ensure that this script has Write permissions to this location, and try again."
			} 
		}
		[string]$CurrentInstaller = $LocalRepo + "\" + $i[1]
		$tempdownloadlocation = $tempdownloadlocation + "\" + $i[1]
		
		IF ($i[4] -eq $True)
		{
			$CurrentInstaller = $CurrentInstaller + "-x64"
			$tempdownloadlocation = $tempdownloadlocation + "-x64"
		}
		
		#Check Current Version
		
		$NewInstaller = GetLatestSoftware $CurrentInstaller $url $tempdownloadlocation $i[1] $i[3] $i[7]
		
		IF ($NewInstaller[0] -eq $True)
		{
			$Version = $NewInstaller[3]
			Write-Host "`nNew Version of $ProgramName Available!"
			Try
			{
				Copy-Item $NewInstaller[1] $LocalRepo -Force -ErrorAction Stop
			} Catch {
				Write-Host "`r`nCould not copy new installer to $LocalRepo.
Please ensure that this script has Write permissions to this location, and try again."
			} Finally {
				IF ($NewInstaller[4])
				{
					Write-Host "
$ProgramName doesn't seem to use the Product Version property in their installers.
Please let them know you want this added!"
				} ELSE {
					Write-Host "$ProgramName updated to version $Version!"
				}
			}
			Start-Job -ScriptBlock {
				param($FileDelete)& {
					WHILE (Test-Path $FileDelete)
					{
						Remove-Item $FileDelete -Force -ErrorAction SilentlyContinue
						Start-Sleep 5
					}
				}
			} -ArgumentList $NewInstaller[1] | out-null
		} ELSEIF ($NewInstaller[0] -eq $False) {
			Write-Host "`r`nNo New Version of $ProgramName Available"
			Start-Job -ScriptBlock {
				param($FileDelete)& {
					WHILE (Test-Path $FileDelete)
					{
						Remove-Item $FileDelete -Force -ErrorAction SilentlyContinue
						Start-Sleep 5
					}
				}
			} -ArgumentList $NewInstaller[1] | out-null
		} ELSEIF ($NewInstaller[0] -eq $Null)
		{
		}
	}
}

Function GetLatestSoftware([string]$CurrentSoftware, [string]$url, [string]$templocation, $Name, $IsMSI, $URLGenerator)
{
	IF ($IsMSI -eq $True)
	{
		$CurrentSoftware = $CurrentSoftware + ".msi"
		$filename = $templocation + ".msi"
		$templocation = $filename
		IF (!(Test-Path $CurrentSoftware))
		{
			$CurrentVersion = "0"
		} ELSE {
			[string]$CurrentVersion = MSI-Version $CurrentSoftware
		}
		
		#Generate Dynamic URL
		
		IF ($URLGenerator -ne $Null)
		{
			$url = Invoke-Command -scriptblock {param($CurrentVersion, $WebClient, $templocation)& $URLGenerator} -ArgumentList $CurrentVersion,$WebClient,$templocation
		}
		
		TRY
		{
			$WebClient.DownloadFile($url,$templocation)
		} CATCH [System.Net.WebException] {
			Start-Sleep 30
			TRY
			{
				$WebClient.DownloadFile($url,$templocation)
				} CATCH [System.Net.WebException] {
					Write-Host "`r`nCould not download installer from $url.
Please check that the web server is reachable. The error was:"
					Write-Host $_.Exception.ToString()
				}
		}
		IF (!(Test-Path $templocation))
		{
			Return $Null, $Null
		}
		[string]$LatestVersion = MSI-Version $templocation
	} ELSE {
	
		$CurrentSoftware = $CurrentSoftware + ".exe"
		$filename = $templocation + ".exe"
		$templocation = $filename
		IF (!(Test-Path $CurrentSoftware))
		{
			$CurrentVersion = "0"
		} ELSE {
			[string]$CurrentVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($CurrentSoftware).ProductVersion
			IF ($CurrentVersion -eq $Null -Or $CurrentVersion -eq "")
			{
				$CurrentVersion = (Get-Item $CurrentSoftware).Length
			}
		}
		
		#Generate Dynamic URL
		
		IF ($URLGenerator -ne $Null)
		{
			$url = Invoke-Command -scriptblock {param($CurrentVersion, $WebClient)& $URLGenerator} -ArgumentList $CurrentVersion,$WebClient
		}
		
		TRY
		{
			$WebClient.DownloadFile($url,$templocation)
		} CATCH [System.Net.WebException] {
			Start-Sleep 30
			TRY
			{
				$WebClient.DownloadFile($url,$templocation)
				} CATCH [System.Net.WebException] {
					Write-Host "`r`nCould not download installer from $url.
Please check that the web server is reachable. The error was:"
					Write-Host $_.Exception.ToString()
				}
		}
		
		IF (!(Test-Path $templocation))
		{
			Return $Null, $Null
		}
		[string]$LatestVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($templocation).ProductVersion
		IF ($LatestVersion -eq $Null -Or $LatestVersion -eq "")
		{
			$LatestVersion = (Get-Item $templocation).Length
			$NoVersion = $True
		}
	}
	
	IF ($CurrentVersion -eq $LatestVersion)
	{
		Return $False, $templocation, $filename, $CurrentVersion
	} ELSE {
		Return $True, $templocation, $filename, $LatestVersion, $NoVersion
	}
	
}

Function MSI-Version([IO.FileInfo]$Path)
{
	$Property = "ProductVersion"
	TRY {
		$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
		$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase","InvokeMethod",$Null,$WindowsInstaller,@($Path.FullName,0))
		$Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
		$View = $MSIDatabase.GetType().InvokeMember("OpenView","InvokeMethod",$null,$MSIDatabase,($Query))
		$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
		$Record = $View.GetType().InvokeMember("Fetch","InvokeMethod",$null,$View,$null)
		$Value = $Record.GetType().InvokeMember("StringData","GetProperty",$null,$Record,1)
		return $Value
	} 
	CATCH {
		Write-Output $_.Exception.Message
	}
}

function Receive-Stream {
	Param([System.IO.Stream]$reader,$fileName,$encoding = [System.Text.Encoding]::GetEncoding($Null))

	IF($fileName) {
		$writer = new-object System.IO.FileStream $fileName, "Create"
	} ELSE {
		[string]$output = ""
	}

	[byte[]]$buffer = new-object byte[] 4096
	[int]$total = [int]$count = 0
	DO
	{
		$count = $reader.Read($buffer, 0, $buffer.Length)
		IF ($fileName)
		{
			$writer.Write($buffer, 0, $count)
		} ELSE {
			$output += $encoding.GetString($buffer, 0, $count)
		}
	} While ($count -gt 0)

	$reader.Close()
	IF (!($fileName))
	{
		$output
	}
}

function Get-FtpDirectory{
	Param($uri,$cred)

	[System.Net.FtpWebRequest]$request = [System.Net.WebRequest]::Create($uri)
	$request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
	$request.Credentials = $cred.GetNetworkCredential()
	$response = $request.GetResponse()
	Receive-Stream $response.GetResponseStream()
}


#Start Logging if Enabled

IF ($LogLocation -ne $Null)
{
	IF (!(Test-Path $LogLocation))
	{
		Try
		{
			New-Item $LogLocation -Type Directory -ErrorAction Stop | Out-Null
		} Catch {
			Write-Host "`r`nCould not create program directory of $LogLocation.
Please ensure that this script has Write permissions to this location, and try again."
		} 
	} ELSE {
		$LogLocation = $LogLocation + "\" + $(get-date -f yyyy-MM-dd-hh-mm) + ".txt"
		Start-Transcript -Path $LogLocation
	}

}

#Running Portion

CLS

IF (!(Test-Path $PackageRepo))
{
	Write-Host "The Package Repository $PackageRepo
Doesn't seem to exist. Please correct before continuing."
	Exit
}
$Packages = Get-ChildItem $PackageRepo -Exclude *Example*, *Template*

IF ($Packages.Count -eq 0)
{
	Write-Host "`r`nYou don't seem to have any Packages in
$PackageRepo
Please add some before continuing."
	Exit
}

$Counter = 0
$Command = "@("
ForEach ($Package in $Packages)
{
	$Command = $Command + [IO.File]::ReadAllText($Package.FullName)
	$Counter ++
	IF ($Packages.Count -ne $Counter)
	{
		$Command = $Command + ","
	}
}
IF ($Packages.Count -le 1)
{
	$Command = $Command + "@('False','False','False','False','False','False','False','False')"
}
$Command = $Command + ")"
$Updates = Invoke-Expression $Command

CheckUpdates

$jobs = (get-job -State Running | Measure-Object).count
IF ($jobs -gt 0)
{
	Write-Host "
	
Cleaning Up Temporary Installers . . . Please Wait"
}
While ($jobs)
{
	start-sleep -seconds 5
	$jobs = (get-job -state running | Measure-Object).count
}
Stop-Transcript