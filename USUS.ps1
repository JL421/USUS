<#
.SYNOPSIS
	Downloads Update packages from specified sources, and updates the Software Repository.
.NOTES
	File Name	: USUS.ps1
	Author		: reddit.com/u/JL421
	Last Update : 2015-04-22
.EXAMPLE
	USUS.ps1 -ConfigDir "D:\Data\Config" -ForceDeploymentPackage
#>

param([Parameter(Mandatory=$True)][string]$ConfigDir, [switch]$ForceDeploymentPackage)

# Define the WebClient

$WebClient = New-Object System.Net.WebClient

#Running Portion

CLS


#Check that the Config Directory Exists

IF (!(Test-Path $ConfigDir))
{
	Write-Host "Your Config Directory $ConfigDir
Doesn't seem to exist, please correct this before continuing.`r`n"
	Start-Sleep 10
	Exit
}


#Import Config File - Essentially a list of variables

$Configs = Get-ChildItem $ConfigDir -Exclude *Example*, *Template* | Where { ! $_.PSIsContainer }

IF ($Configs.Count -eq 0)
{
	Write-Host "You don't seem to have any base config files specified in $ConfigDir
Please correct this before continuing.`r`n"
	Exit
}

ForEach ($Config in $Configs)
{
	$ConfigCommand = [IO.File]::ReadAllText($Config.FullName)
	Invoke-Expression $ConfigCommand
}


#Verify $SoftwareRepo

IF (!(Test-Path $SoftwareRepo))
{
	CLS
	Write-Host "Software Repository $SoftwareRepo dosen't seem to exist.
Please create this location or run this script with the credentials required to access it.`r`n"
	Exit
}


#If one of the packages requiring a batch file is specified, enable batch file creation

IF ($PDQ -Or $SFX)
{
	$BatchFiles = $True
}

#Define the Includes and Packages directories

$IncludesDir = $ConfigDir + "\Includes"
$PackagesDir = $ConfigDir + "\Packages"


#Test that the Includes Directory Exists

IF (!(Test-Path $IncludesDir))
{
	Write-Host "Your Includes Directory $IncludesDir
Doesn't seem to exist, please correct this before continuing.`r`n"
	Exit
}


#Import the Includes - Functions

$Includes = Get-ChildItem $IncludesDir -Exclude *Example*, *Template*

IF ($Includes.Count -eq 0)
{
	Write-Host "You don't seem to have any Includes in $IncludesDir
Please correct this before continuing.`r`n"
	Exit
}

ForEach ($Include in $Includes)
{
	$IncludeCommand = [IO.File]::ReadAllText($Include.FullName)
	Invoke-Expression $IncludeCommand
}


#Get the packages for update checking

$Updates = Get-Packages


#Miscellaneous Variables

$TimeDateString = $(get-date -f yyyy-MM-dd-HH:mm)


#Setup the Update Logs

$InstallerVersionReportLocation = $SoftwareRepo + "\Installer Versions.txt"
$InstallerChangeReportLocation = $SoftwareRepo + "\Installer Changes.txt"

"`r`nPackages in Use`r`n-----`r`n" | Out-File $InstallerVersionReportLocation
"`r`nPackages Updated on Last Run`r`n-----`r`n" | Out-File $InstallerChangeReportLocation

#Run the main function that processes the update packages and returns an array of updates processed

$UpdateResults = ProcessPackages | Invoke-Expression


#Send the Email Report (If everything was defined correctly)

IF ($EmailReport -eq $True)
{
	EmailReport
}


#Wait for the Temporary Installer cleanup to finish

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

#End
