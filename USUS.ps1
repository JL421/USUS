<#
.SYNOPSIS
	Downloads Update packages from specified sources, and updates the Software Repository.
.NOTES
	File Name	: USUS.ps1
	Author		: reddit.com/u/JL421
	Last Update : 2015-04-08
.EXAMPLE
	USUS.ps1 -SoftwareRepo "D:\Data\SoftwareRepo" -ConfigDir "D:\Data\Config" -EnableLogging -ForceDeploymentPackage
#>

param([Parameter(Mandatory=$True)][string]$ConfigDir,[switch]$EnableLogging, [switch]$ForceDeploymentPackage)

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
	$RunLog = $LogsDir + "\" + $(get-date -f yyyy-MM-dd-HH-mm) + ".txt"
	Start-Transcript $RunLog
}

CLS

$Configs = Get-ChildItem $ConfigDir -Exclude *Example*, *Template* | Where { ! $_.PSIsContainer }

IF ($Configs.Count -eq 0)
{
	Write-Host "You don't seem to have any base config files specified in $ConfigDir
Please correct this before continuing.`r`n"
	Stop-Transcript
	Exit
}

ForEach ($Config in $Configs)
{
	$ConfigCommand = [IO.File]::ReadAllText($Config.FullName)
	Invoke-Expression $ConfigCommand
}

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

$Updates = Get-Packages

$InstallerVersionReportLocation = $SoftwareRepo + "\Installer Versions.txt"
$InstallerChangeReportLocation = $SoftwareRepo + "\Installer Changes.txt"

"`r`nPackages in Use`r`n-----`r`n" | Out-File $InstallerVersionReportLocation
"`r`nPackages Updated on Last Run`r`n-----`r`n" | Out-File $InstallerChangeReportLocation

ProcessPackages

"-----`r`nLast Updated - $(get-date -f yyyy-MM-dd-HH-mm)" | Out-File $InstallerVersionReportLocation -Append
"-----`r`nLast Updated - $(get-date -f yyyy-MM-dd-HH-mm)" | Out-File $InstallerChangeReportLocation -Append

IF ($EmailReport -eq $True)
{
	IF (($EmailTo -eq $Null) -Or ($EmailSubject -eq $Null) -Or ($EmailServer -eq $Null) -Or ($EmailFrom -eq $Null))
	{
		Write-Host "It looks like you want to send an Email Report, but you are missing some of the required parameters.
Please correct this before continuing."
		Break
	}
	$EmailBody = [IO.File]::ReadAllText($InstallerChangeReportLocation) + [IO.File]::ReadAllText($InstallerVersionReportLocation)
		
	$EmailClient.Send($EmailFrom, $EmailTo, $EmailSubject, $EmailBody)
}



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