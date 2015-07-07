<#
.SYNOPSIS
	Downloads Update packages from specified sources, and updates the Software Repository.
.NOTES
	File Name	: USUS.ps1
	Author		: Jason Lorsung (jason@jasonlorsung.com)
	Last Update : 2015-07-06
	Version		: 1.4
.EXAMPLE
	USUS.ps1 -ConfigDir "D:\Data\Config" -ForceDeploymentPackage
#>

param([string]$ConfigDir, [switch]$ForceDeploymentPackage, [switch]$InitialSetup)

# Define the WebClient

$WebClient = New-Object System.Net.WebClient

#Running Portion

CLS

#InitialSetup

IF(!($ConfigDir))
{
	$InitialSetup = $True
}

IF($InitialSetup -eq $True)
{
	$header = "USUS V1.4"
	$WebClient.Headers.Add("user-agent", $header)
	CLS
	Write-Host "Welcome to USUS
Running Initial Setup . . ."
	[string]$ConfigDir = Read-Host 'Where do you want your Config Dir? '
	
	$ConfigFileLocation = $ConfigDir + "\Config.conf"
	
	IF (Test-Path $ConfigDir)
	{
		IF (Test-Path $ConfigFileLocation)
		{
			Write-Host "Existing Config Found...
Importing Current Config"
			$ConfigCommand = [IO.FILE]::ReadAllText($ConfigFileLocation)
			Invoke-Expression $ConfigCommand
		}
	} ELSE {
		Try
		{
			New-Item $ConfigDir -Type Directory -ErrorAction Stop | Out-Null
		} Catch {
			Write-Host "Could not create program directory of $ConfigDir.
Please ensure that the user running this script has Write permissions to this location, and try again.`r`n"
		} 
	}
	
	IF (!($SoftwareRepo))
	{
		[string]$SoftwareRepo = Read-Host 'Where is your Software Repo? '
	} ELSE {
		IF (([string]$SoftwareRepoTemp = Read-Host "Where is your Software Repo? : [$SoftwareRepo]") -ne '')
		{
			$SoftwareRepo = $SoftwareRepoTemp
		}		
	}
	
	IF (!($ArchiveOldVersions))
	{
		[string]$ArchiveOldVersionsTemp = Read-Host "Would you like to Archive Old Software Versions? :[n]"
		IF ($ArchiveOldVersionsTemp.ToLower().StartsWith("y"))
		{
			$ArchiveOldVersions = $True
		} ELSE {
			$ArchiveOldVersions = $False
		}
	} ELSE {
		[string]$ArchiveOldVersionsTemp = Read-Host "Would you like to Archive Old Software Versions? :[y]"
		IF ($ArchiveOldVersionsTemp.ToLower().StartsWith("n"))
		{
			$ArchiveOldVersions = $False
		} ELSE {
			$ArchiveOldVersions = $True
		}
	}
	
	IF (!($BatchFiles))
	{
		[string]$BatchFilesTemp = Read-Host "Would you like to Create Batch Files? :[n]"
		IF ($BatchFilesTemp.ToLower().StartsWith("y"))
		{
			$BatchFiles = $True
		} ELSE {
			$BatchFiles = $False
		}
	} ELSE {
		[string]$BatchFilesTemp = Read-Host "Would you like to Create Batch Files? :[y]"
		IF ($BatchFilesTemp.ToLower().StartsWith("n"))
		{
			$BatchFiles = $False
		} ELSE {
			$BatchFiles = $True
		}
	}
	
	IF (!($Lansweeper))
	{
		[string]$LansweeperTemp = Read-Host "Would you like to Create Lansweeper Packages? :[n]"
		IF ($LansweeperTemp.ToLower().StartsWith("y"))
		{
			$Lansweeper = $True
		} ELSE {
			$Lansweeper = $False
		}
	} ELSE {
		[string]$LansweeperTemp = Read-Host "Would you like to Create Lansweeper Packages? :[y]"
		IF ($LansweeperTemp.ToLower().StartsWith("n"))
		{
			$Lansweeper = $False
		} ELSE {
			$Lansweeper = $True
		}
	}
	
	IF ($Lansweeper)
	{
		IF (!($LansweeperRepo))
		{
			[string]$LansweeperRepo = Read-Host 'Where is your Lansweeper Repo? '
		} ELSE {
			IF (([string]$LansweeperRepoTemp = Read-Host "Where is your Lansweeper Repo? : [$LansweeperRepo]") -ne '')
			{
				$LansweeperRepo = $LansweeperRepoTemp
			}			
		}
	}
	
	IF (!($PDQ))
	{
		[string]$PDQTemp = Read-Host "Would you like to Create PDQ Packages? :[n]"
		IF ($PDQTemp.ToLower().StartsWith("y"))
		{
			$PDQ = $True
		} ELSE {
			$PDQ = $False
		}
	} ELSE {
		[string]$PDQTemp = Read-Host "Would you like to Create PDQ Packages? :[y]"
		IF ($PDQTemp.ToLower().StartsWith("n"))
		{
			$PDQ = $False
		} ELSE {
			$PDQ = $True
		}
	}
	
	IF (!($SFX))
	{
		[string]$SFXTemp = Read-Host "Would you like to Create SFX Packages? :[n]"
		IF ($SFXTemp.ToLower().StartsWith("y"))
		{
			$SFX = $True
		} ELSE {
			$SFX = $False
		}
	} ELSE {
		[string]$SFXTemp = Read-Host "Would you like to Create SFX Packages? :[y]"
		IF ($SFXTemp.ToLower().StartsWith("n"))
		{
			$SFX = $False
		} ELSE {
			$SFX = $True
		}
	}
	
	IF (!($EmailReport))
	{
		[string]$EmailReportTemp = Read-Host "Would you like to Send Email Reports? :[n]"
		IF ($EmailReportTemp.ToLower().StartsWith("y"))
		{
			$EmailReport = $True
		} ELSE {
			$EmailReport = $False
		}
	} ELSE {
		[string]$EmailReportTemp = Read-Host "Would you like to Send Email Reports? :[y]"
		IF ($EmailReportTemp.ToLower().StartsWith("n"))
		{
			$EmailReport = $False
		} ELSE {
			$EmailReport = $True
		}
	}
	
	IF ($PDQ -Or $SFX)
	{
		$BatchFiles = $True
	}
	
	$ConfigFileContents = '#Storage location for Installers

$SoftwareRepo = "' + $SoftwareRepo + '"

$ArchiveOldVersions = $' + $ArchiveOldVersions + '

#Deployment Package Types

$BatchFiles = $' + $BatchFiles + '

$Lansweeper = $' + $Lansweeper + '
$LansweeperRepo = "' + $LansweeperRepo + '"

$PDQ = $' + $PDQ + '
$SFX = $' + $SFX + '

#Email Reporting Settings

'
	
	IF ($EmailReport -eq $True)
	{
		IF (!($EmailOnNewVersionOnly))
		{
			[string]$EmailOnNewVersionOnlyTemp = Read-Host "Would you like to Send Email Reports On New Versions Only? :[n]"
			IF ($EmailOnNewVersionOnlyTemp.ToLower().StartsWith("y"))
			{
				$EmailOnNewVersionOnly = $True
			} ELSE {
				$EmailOnNewVersionOnly = $False
			}
		} ELSE {
			[string]$EmailOnNewVersionOnlyTemp = Read-Host "Would you like to Send Email Reports On New Versions Only? :[y]"
			IF ($EmailOnNewVersionOnlyTemp.ToLower().StartsWith("n"))
			{
				$EmailOnNewVersionOnly = $False
			} ELSE {
				$EmailOnNewVersionOnly = $True
			}
		}
	
		IF (!($EmailFrom))
		{
			[string]$EmailFrom = Read-Host 'Who is your Email From? '
		} ELSE {
			IF (([string]$EmailFromTemp = Read-Host "Who is your Email From? : [$EmailFrom]") -ne '')
			{
				$EmailFrom = $EmailFromTemp
			}			
		}
	
		IF (!($EmailTo))
		{
			[string]$EmailTo = Read-Host 'Who is your Email To? (Comma Separated List)'
		} ELSE {
			IF (([string]$EmailToTemp = Read-Host "Who is your Email To? : [$EmailTo]") -ne '')
			{
				$EmailTo = $EmailToTemp
			}			
		}
	
		[string]$EmailSubjectTemp = Read-Host "What should your Email Subject Be? [USUS Report - yyyy-MM-dd-HH:mm]"
	
		IF ($EmailSubjectTemp -ne '')
		{
			$EmailSubject = $EmailSubjectTemp
		} ELSE {
			$EmailSubject = 'USUS Report - $(get-date -f yyyy-MM-dd-HH:mm)'
		}
	
		IF (!($EmailServer))
		{
			[string]$EmailServer = Read-Host 'What is your Email Server? '
		} ELSE {
			IF (([string]$EmailServerTemp = Read-Host "What is your Email Server? : [$EmailServer]") -ne '')
			{
				$EmailServer = $EmailServerTemp
			}			
		}
	
	
		IF (([string]$EmailServerPort = Read-Host "What is your Email Server Port? ") -ne '')
		{
			[string]$EmailServerPort = $EmailServerPort
		}
	
		IF (!($EmailClient.EnableSsl))
		{
			[string]$EmailClientEnableSslTemp = Read-Host "Does your mail server Require SSL? :[n]"
			IF ($EmailClientEnableSslTemp.ToLower().StartsWith("y"))
			{
				$EmailClientEnableSsl = $True
			} ELSE {
				$EmailClientEnableSsl = $False
			}
		} ELSE {
			[string]$EmailClientEnableSslTemp = Read-Host "Does your mail server Require SSL? :[y]"
			IF ($EmailClientEnableSslTemp.ToLower().StartsWith("n"))
			{
				$EmailClientEnableSsl = $False
			} ELSE {
				$EmailClientEnableSsl = $True
			}
		}
	
		[string]$EmailClientCredentialsUser = Read-Host 'What is your Email Username? '
		[string]$EmailClientCredentialsPass = Read-Host 'What is your Email Password? '
	
	
		IF (!($EmailCCs))
		{
			IF (([string]$EmailCCs = Read-Host 'Who is your Email CCed To? (Comma Separated List) ') -eq '')
			{
				$EmailCCs = '$Null'
			}
		} ELSE {
			IF (([string]$EmailCCsTemp = Read-Host "Who is your Email CCed To? (Comma Separated List) : [$EmailCCs]") -ne '')
			{
				$EmailCCs = '"' + $EmailCCsTemp + '"'
			}			
		}
		
		$ConfigFileContents = $ConfigFileContents + '$EmailReport = $' + $EmailReport + '
$EmailOnNewVersionOnly = $' + $EmailOnNewVersionOnly + '
$EmailFrom = "' + $EmailFrom + '"
$EmailTo = "' + $EmailTo + '"
$EmailSubject = "' + $EmailSubject + '"
$EmailServer = "' + $EmailServer + '"
$EmailClient = New-Object Net.Mail.SmtpClient($EmailServer, ' + $EmailServerPort + ')
$EmailClient.EnableSsl = $' + $EmailClientEnableSsl + '
$EmailClient.Credentials = New-Object System.Net.NetworkCredential("' + $EmailClientCredentialsUser + '", "' + $EmailClientCredentialsPass + '")
$EmailCCs = ' + $EmailCCs
	} ELSE {
		$ConfigFileContents = $ConfigFileContents + '#$EmailOnNewVersionOnly = $True or $False
#$EmailFrom = "From Address"
#$EmailTo = "To List"
#$EmailSubject = "USUS Report - $(get-date -f yyyy-MM-dd-HH-mm)"
#$EmailServer = "Mail Server"
#$EmailClient = New-Object Net.Mail.SmtpClient($EmailServer, Port)
#$EmailClient.EnableSsl = $True or $False
#$EmailClient.Credentials = New-Object System.Net.NetworkCredential("Username", "Password")
#$EmailCCs = "CC List" or $Null'		
	}
	
	$ConfigFileContents | Out-File $ConfigFileLocation
	$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
	$SetupFinish = '
	
This config has been written. To launch USUS in the future and skip this setup, use the following command:

powershell.exe -ExecutionPolicy Bypass -File "' + $scriptPath + '\USUS.ps1" -ConfigDir "' + $ConfigDir + '"'
	Write-Host $SetupFinish
	Write-Host "Press any key to continue ..."

	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	
}

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
