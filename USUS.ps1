<#
.SYNOPSIS
	Downloads Update packages from specified sources, and updates the Software Repository.
.NOTES
	File Name	: USUS.ps1
	Author		: reddit.com/u/JL421
	Last Update : 2015-04-08
.EXAMPLE
	USUS.ps1 -SoftwareRepo "D:\Data\SoftwareRepo" -ConfigDir "D:\Data\Config" -EnableLogging
#>

param([Parameter(Mandatory=$True)][string]$SoftwareRepo,[Parameter(Mandatory=$True)][string]$ConfigDir,[switch]$EnableLogging)

# Define the WebClient

$WebClient = New-Object System.Net.WebClient

#Running Portion

CLS

IF (!(Test-Path $ConfigDir))
{
	Write-Host "Your Config Directory $ConfigDir
Doesn't seem to exist, please correct this before continuing.`r`n"
	Start-Sleep 10
	Exit
}

$LogsDir = $ConfigDir + "\Logs"

IF ($EnableLogging)
{
	IF (!(Test-Path $LogsDir))
	{
		Try
		{
			New-Item $LogsDir -Type Directory -ErrorAction Stop | Out-Null
		} Catch {
			Write-Host "Could not create Log Directory of $LogsDir.
	Please ensure that this script has Write permissions to this location, or disable logging, and try again.`r`n"
	Start-Sleep 10
		}
	}
	$RunLog = $LogsDir + "\" + $(get-date -f yyyy-MM-dd-hh-mm) + ".txt"
	Start-Transcript $RunLog
}

CLS

$IncludesDir = $ConfigDir + "\Includes"
$PackagesDir = $ConfigDir + "\Packages"

IF (!(Test-Path $IncludesDir))
{
	Write-Host "Your Includes Directory $IncludesDir
Doesn't seem to exist, please correct this before continuing.`r`n"
	Start-Sleep 10
	Exit
}

$Includes = Get-ChildItem $IncludesDir -Exclude *Example*, *Template*

IF ($Includes.Count -eq 0)
{
	Write-Host "You don't seem to have any Includes in $IncludesDir
Please correct this before continuing.`r`n"
	Stop-Transcript
	Exit
}

ForEach ($Include in $Includes)
{
	$IncludeCommand = [IO.File]::ReadAllText($Include.FullName)
	Invoke-Expression $IncludeCommand
}

IF (!(Test-Path $PackagesDir))
{
	Write-Host "The Package Repository $PackagesDir
Doesn't seem to exist. Please correct before continuing.`r`n"
	Exit
}
$Packages = Get-ChildItem $PackagesDir -Exclude *Example*, *Template*

IF ($Packages.Count -eq 0)
{
	Write-Host "You don't seem to have any Packages in
$PackageRepo
Please add some before continuing.`r`n"
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
	
Cleaning Up Temporary Installers . . . Please Wait`r`n"
}
While ($jobs)
{
	start-sleep -seconds 5
	$jobs = (get-job -state running | Measure-Object).count
}
Stop-Transcript