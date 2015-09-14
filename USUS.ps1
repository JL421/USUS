<#
.SYNOPSIS
	Downloads Update packages from specified sources, and updates the Software Repository.
.NOTES
	File Name	: USUS.ps1
	Author		: Jason Lorsung (jason@jasonlorsung.com)
	Last Update : 2015-07-26
	Version		: 2.0
.EXAMPLE
	USUS.ps1 -ConfigFile "D:\Data\Config.xml"
.VARIABLES
		.IMPORTED
			$PackagesRepo - Storage Repository for downloaded package files
			$SoftwareRepo - Storage Repository for downloaded software
		.GENERAL
			$ConfigFile - Location for the XML Config file
		.GENERATED
			$Configuration - The content of the XML Config File
			$Package - Individual Package to be processed
			$PackageName - Name of the package
			$Packages - Null package for XML Package Master
			$PackageMaster - The content of the XML Package Master File
			$PackageMasterFile - Location of the XML Package Master File containing the content of all the updated packages
			$UnimportedPackages - List of packages that have not been imported into the XML Package Master File

#>

param([Parameter(Mandatory=$True)][string]$ConfigFile)

IF (!(Test-Path $ConfigFile))
{
	Write-Output "Your specified config ($ConfigFile) doesn't seem to exist, or the user running this script doesn't have access to read it.
Please correct this and try again."
	Exit
}

[xml]$Configuration = Get-Content $ConfigFile

#Test for required variables

IF (!($Configuration.config))
{
	Write-Output "Your config file seems to be missing its configuration. Please correct this and try again."
	Exit
}

IF (!($Configuration.config.softwarerepo))
{
	Write-Output "Your Software Repo is not defined. Please correct this and try again."
	Exit
}

IF (!(Test-Path $Configuration.config.softwarerepo))
{
	Write-Output "Your specified software repo ($Configuration.config.softwarerepo) doesn't seem to exist, or the user running this script
doesn't have access to read it. Please correct this and try again."
	Exit
}

IF (!(Test-Path $Configuration.config.packagesrepo))
{
	Write-Output "Your specified package repo ($Configuration.config.packagesrepo) doesn't seem to exist, or the user running this script
doesn't have access to read it. Please correct this and try again."
	Exit
}


$PackageMasterFile = $Configuration.config.packagesrepo.TrimEnd("\") + "\PackageMaster.xml"
IF (!(Test-Path $PackageMasterFile))
{
	$PackageMaster = New-Object System.Xml.XmlDocument
	$Packages = $PackageMaster.CreateElement("Packages")
	$PackageMaster.AppendChild($Packages) | Out-Null
	$Packages.AppendChild($PackageMaster.CreateElement("NullPackage")) | Out-Null
	$PackageMaster.Save($PackageMasterFile)
}

[xml]$PackageMaster = Get-Content $PackageMasterFile

$UnimportedPackages = Get-ChildItem $Configuration.config.packagesrepo -Exclude *Example*, *Template*, PackageMaster.xml -Include *.xml -Recurse | Where-Object { !$_.PSIsContainer}

ForEach ($UnimportedPackage in $UnimportedPackages)
{
	[xml]$Package = Get-Content $UnimportedPackage
	IF (($Package.SelectNodes("//Name") | Where-Object { $_.InnerText -ne $Null }) -eq $Null)
	{
		Write-Debug "Package $UnimportedPackage doesn't seem to be valid, skipping..."
		Continue
	}
	IF (($Package.SelectNodes("//Verify") | Where-Object { $_.InnerText -eq "USUS XML Package File" -And $_.InnerText -ne $Null}) -eq $Null)
	{
		Write-Debug "Package $UnimportedPackage doesn't seem to be valid, skipping..."
		Continue
	}
	
	$PackageName = $Package.package.Name
	
	IF (($PackageMaster.SelectNodes("//Packages/package/Name[text() = '$PackageName']")).Count -ne 0)
	{
		Write-Debug "Package $UnimportedPackage already exists in Package Master, skipping..." -debug
		Continue
	}
	$PackageMaster.Packages.AppendChild($PackageMaster.ImportNode($Package.Package,$true)) | Out-Null
	Remove-Item $UnimportedPackage
	$PackageMaster.Save($PackageMasterFile)
}

$SoftwareMasterFile = $Configuration.config.softwarerepo.TrimEnd("\") + "\SoftwareMaster.xml"
IF (!(Test-Path $SoftwareMasterFile))
{
	$SoftwareMaster = New-Object System.Xml.XmlDocument
	$Software = $SoftwareMaster.CreateElement("SoftwarePackages")
	$SoftwareMaster.AppendChild($Software) | Out-Null
	$Software.AppendChild($SoftwareMaster.CreateElement("NullSoftware")) | Out-Null
	$SoftwareMaster.Save($SoftwareMasterFile)
}

[xml]$SoftwareMaster = Get-Content $SoftwareMasterFile

ForEach ($Package in $PackageMaster.SelectNodes("//Packages/package"))
{
	Write-Output $Package.Name
	Write-Output Success
	
	$PackageName = $Package.Name
	
	IF (!(($SoftwareMaster.SelectNodes("//SoftwarePackages/software/Name[text() = '$PackageName']")).Count -ne 0))
	{
		$Software = $SoftwareMaster.CreateElement("software")
		$SoftwareMaster.SoftwarePackages.AppendChild($Software) | Out-Null
		$Software.AppendChild($SoftwareMaster.CreateElement("Name")) | Out-Null
		$Software.Name = $PackageName
		$SoftwareMaster.Save($SoftwareMasterFile)
	} ELSE {
		$Software = $SoftwareMaster.SelectNodes("//SoftwarePackages/software/Name") | Where-Object { $_.InnerText -eq $PackageName }
	}
	
	IF (!(($Package.SelectNodes("//CustomPath") | Where-Object { $_.InnerText -ne $Null }) -eq $Null))
	{
		$LocalRepo = $Package.CustomPath
		IF (!(Test-Path $LocalRepo))
		{
			Write-Output "Software Repository $LocalRepo doesn't seem to exist.
			Please create this location or run this script with the credentials required to access it."
			Continue
		}
	} ELSE {
		$LocalRepo = $Configuration.config.softwarerepo
	}
	
	$CurrentInstaller = $LocalRepo + "\" + $Package.Name + "\" + $Package.Name
	
	IF (!(($Package.SelectNodes("//DownloadURL") | Where-Object { $_.InnerText -ne $Null }) -eq $Null))
	{
		$CurrentInstaller32 = $CurrentInstaller + "-x32"
		IF ($Package.IsMSI)
		{
			$CurrentInstaller32 = $CurrentInstaller32 + ".msi"
		} ELSE {
			$CurrentInstaller32 = $CurrentInstaller32 + ".exe"
		}
	}
	
	IF (!(($Package.SelectNodes("//DownloadURL64") | Where-Object { $_.InnerText -ne $Null }) -eq $Null))
	{
		$CurrentInstaller64 = $CurrentInstaller + "-x64"
		IF ($Package.IsMSI)
		{
			$CurrentInstaller64 = $CurrentInstaller64 + ".msi"
		} ELSE {
			$CurrentInstaller64 = $CurrentInstaller64 + ".exe"
		}
	}
	
	IF (($Software.SelectNodes("//Versions/version")).Count -eq 0)
	{
		IF ($Package.IsMSI)
		{
			IF (!($CurrentInstaller32))
			{
				IF (!(Test-Path $CurrentInstaller32))
				{
					$CurrentVersion32 = "0"
				} ELSE {
					[string]$CurrentVersion32 = MSI-Version $CurrentInstaller32
				}
			}
			
			IF (!($CurrentInstaller64))
			{
				IF (!(Test-Path $CurrentInstaller64))
				{
					$CurrentVersion64 = "0"
				} ELSE {
					[string]$CurrentVersion64 = MSI-Version $CurrentInstaller64
				}
			}
		} ELSE {
			IF (!($CurrentInstaller32)
			{
				IF (!(Test-Path $CurrentInstaller32))
				{
					$CurrentVersion32 = "0"
				} ELSE {
					[string]$CurrentVersion32 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($CurrentInstaller32).FileVersion
					IF ($CurrentVersion32 -eq $Null -Or $CurrentVersion32 -eq "")
					{
						$CurrentVersion32 = (Get-Item $CurrentInstaller32).Length
					}
				}
			}
			IF (!($CurrentInstaller64))
			{
				$CurrentInstaller64 = $LocalRepo + "\" + $Package.Name + "\" + $Package.Name + "-64.exe"
				IF (!(Test-Path $CurrentInstaller64))
				{
					$CurrentVersion64 = "0"
				} ELSE {
					[string]$CurrentVersion64 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($CurrentInstaller64).FileVersion
					IF ($CurrentVersion64 -eq $Null -Or $CurrentVersion64 -eq "")
					{
						$CurrentVersion64 = (Get-Item $CurrentInstaller64).Length
					}
				}
			}					
		}
	} ELSE {
		IF (!($CurrentInstaller32))
		
		$Software.SelectNodes("//Versions/version") | Sort-Object | Select-Object -first 1
	}
	
	
	
}

#Cleanup Package and Software Master Files

#End

#Functions

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
