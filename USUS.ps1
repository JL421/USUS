<#
.SYNOPSIS
	Downloads Update packages from specified sources, and updates the Software Repository.
.NOTES
	File Name	: USUS.ps1
	Author		: Jason Lorsung (jason@jasonlorsung.com)
	Last Update : 2015-09-16
	Version		: 2.0
.EXAMPLE
	USUS.ps1 -ConfigFile "D:\Data\Config.xml"
.FLAGS
	-ConfigFile		Use this to specify a Config.XML file for the script to user
	-DebugEnable	Use this to enable Debug output
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

param([Parameter(Mandatory=$True)][string]$ConfigFile, [switch]$DebugEnable)

#Functions

Function Generate-URL ($BitCount, $CurrentVersion, $Package, $WebClient)
{
	IF ($BitCount -eq "32")
	{
		IF (!($Package.DownloadURL32))
		{
			IF (($Package.URLGenerator32.URLGenerator).Count -ne 0)
			{
				$URLGenerator = ""
				$Package.URLGenerator32.URLGenerator | ForEach {
					$URLGenerator = $URLGenerator + "`r`n" + $_
				}
				$URLGenerator = [scriptblock]::Create($URLGenerator)
				$VersionURL = Invoke-Command -scriptblock {param($CurrentVersion, $WebClient)& $URLGenerator} -ArgumentList $CurrentVersion,$WebClient
				IF (!($VersionURL -like "Error*") -Or !($VersionURL -like "Exception*"))
				{
					IF ($VersionURL.Count -eq 2)
					{
						$DownloadURL = $VersionURL[0]
						[string]$LatestVersion = $VersionURL[1]
						$LatestVersion = $LatestVersion.Trim()
						return $DownloadURL, $LatestVersion
					} ELSEIF ($VersionURL -ne $Null) {
						$DownloadURL = $VersionURL
						return $DownloadURL, "No Version Retrieved"
					}
				} ELSE {
				
					Write-Debug "Error occurred while retrieving URL for package $PackageName
					The error was $VersionURL"
					Continue
				}
			}
		} ELSE {
			$DownloadURL = $Package.DownloadURL32
			return $DownloadURL, "No Version Retrieved"
		}
	} ELSEIF ($BitCount -eq "64") {
		IF (!($Package.DownloadURL64))
		{
			IF (($Package.URLGenerator64.URLGenerator).Count -ne 0)
			{
				$URLGenerator = ""
				$Package.URLGenerator64.URLGenerator | ForEach {
					$URLGenerator = $URLGenerator + "`r`n" + $_
				}
				$URLGenerator = [scriptblock]::Create($URLGenerator)
				$VersionURL = Invoke-Command -scriptblock {param($CurrentVersion, $WebClient)& $URLGenerator} -ArgumentList $CurrentVersion,$WebClient
				IF (!($VersionURL -like "Error*") -Or !($VersionURL -like "Exception*"))
				{
					IF ($VersionURL.Count -eq 2)
					{
						$DownloadURL = $VersionURL[0]
						[string]$LatestVersion = $VersionURL[1]
						$LatestVersion = $LatestVersion.Trim()
						return $DownloadURL, $LatestVersion
					} ELSEIF ($VersionURL -ne $Null) {
						$DownloadURL = $VersionURL
						return $DownloadURL, "No Version Retrieved"
					}
				} ELSE {
				
					Write-Debug "Error occurred while retrieving URL for package $PackageName
					The error was $VersionURL"
					Continue
				}
			}
		} ELSE {
			$DownloadURL = $Package.DownloadURL64
			return $DownloadURL, "No Version Retrieved"
		}
	}
}

Function Get-LatestInstaller ($CurentVersion, $DownloadURL, $LatestVersion, $Package, $templocation)
{
	IF ($Package.IsMSI)
	{	
		IF ($DownloadURL -ne $Null)
		{
			IF ($LatestVersion -eq $Null -Or (!($LatestVersion)) -Or $LatestVersion -eq "")
			{
				Get-NewInstaller $DownloadURL $templocation
				[string]$LatestVersion = MSI-Version $templocation
				IF ($LatestVersion -like "Error*" -Or $LatestVersion -like "Exception*")
				{
					Write-Debug $LatestVersion
					Continue
				}
				$LatestVersion = $LatestVersion.Trim()
				return $LatestVersion
			} ELSE {
				IF ($CurrentVersion -ne $LatestVersion)
				{
					Get-NewInstaller $DownloadURL $templocation
					return $LatestVersion
				}
				
				return $LatestVersion
			}
		}
	} ELSE {
		IF ($DownloadURL)
		{
			IF ($LatestVersion -eq $Null -Or (!($LatestVersion)) -Or $LatestVersion -eq "")
			{				
				Get-NewInstaller $DownloadURL $templocation
				[string]$LatestVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($templocation).FileVersion
				$LatestVersion = $LatestVersion.Trim()
				IF ($LatestVersion -eq $Null -Or $LatestVersion -eq "")
				{
					$LatestVersion = (Get-Item $templocation).Length
					$LatestVersion = $LatestVersion.Trim()
					return $LatestVersion
				}
			} ELSE {
				IF ($CurrentVersion -ne $LatestVersion)
				{
					Get-NewInstaller $DownloadURL $templocation
					IF ($ForceDownload)
					{
						[string]$LatestVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($templocation).FileVersion
						$LatestVersion = $LatestVersion.Trim()
						return $LatestVersion
					}
					
					return $LatestVersion
				}
				
				return $LatestVersion
			}
		}
	}
}

Function Get-NewInstaller([string]$url, [string]$templocation)
{
	TRY
	{
		$WebClient.DownloadFile($url,$templocation)
	} CATCH [System.Net.WebException] {
		Start-Sleep 30
		TRY
		{
			$WebClient.DownloadFile($url,$templocation)
		} CATCH [System.Net.WebException] {
			Write-Debug "Could not download installer from $url.
Please check that the web server is reachable. The error was:"
			Write-Debug $_.Exception.ToString()
			Write-Debug "`r`n"
		}
	}
	IF (!(Test-Path $templocation))
	{
		Return $Null, $Null
	}
}

Function Get-SoftwareVersion ($BitCount, $CurrentInstaller, $Package, $Software)
{	
	IF ($Package.DownloadURL32 -Or $Package.DownloadURL64 -Or $Package.URLGenerator32 -Or $Package.URLGenerator64)
	{
		IF ((!($Software.Versions32) -And ($BitCount -eq "32")) -Or (!($Software.Versions64) -And ($BitCount -eq "64")))
		{			
			IF ($Package.IsMSI)
			{
				IF (!(Test-Path $CurrentInstaller))
				{
					$CurrentVersion = "0"
				} ELSE {
					[string]$CurrentVersion = MSI-Version $CurrentInstaller
					IF ($CurrentVersion -like "Error*" -Or $CurrentVersion -like "Exception*")
					{
						Return $CurrentVersion
					}
					$CurrentVersion = $CurrentVersion.Trim()
					
					IF ($BitCount -eq "32")
					{

						$Versions = $SoftwareMaster.CreateElement("Versions32")
						$Software.AppendChild($Versions) | Out-Null
						$SoftwareMaster.Save($SoftwareMasterFile)

					} ELSEIF ($BitCount -eq "64") {
						$Versions = $SoftwareMaster.CreateElement("Versions64")
						$Software.AppendChild($Versions) | Out-Null
						$SoftwareMaster.Save($SoftwareMasterFile)
					}
					
					$version = $SoftwareMaster.CreateElement("version")
					$Versions.AppendChild($version) | Out-Null
					$location = $SoftwareMaster.CreateElement("Location")
					$location.InnerText = $CurrentInstaller
					$version.AppendChild($location) | Out-Null
					$version.SetAttribute("name", $CurrentVersion)
					$SoftwareMaster.Save($SoftwareMasterFile)
				}
				
				return $CurrentVersion, $False
			} ELSE {
				IF (!(Test-Path $CurrentInstaller))
				{
					$CurrentVersion = "0"
				} ELSE {
					[string]$CurrentVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($CurrentInstaller).FileVersion
					$CurrentVersion = $CurrentVersion.Trim()
					$CurrentVersion = $CurrentVersion -split "[\n\r\s]" | Select-Object -Index 0
					IF ($CurrentVersion -eq $Null -Or $CurrentVersion -eq "")
					{
						$CurrentVersion = (Get-Item $CurrentInstaller).Length
					} ELSE {
						IF ($BitCount -eq "32")
						{
							$Versions = $SoftwareMaster.CreateElement("Versions32")
							$Software.AppendChild($Versions) | Out-Null
							$SoftwareMaster.Save($SoftwareMasterFile)
						} ELSEIF ($BitCount -eq "64") {
							$Versions = $SoftwareMaster.CreateElement("Versions64")
							$Software.AppendChild($Versions) | Out-Null
							$SoftwareMaster.Save($SoftwareMasterFile)
						}
						
						$version = $SoftwareMaster.CreateElement("version")
						$Versions.AppendChild($version) | Out-Null
						$location = $SoftwareMaster.CreateElement("Location")
						$location.InnerText = $CurrentInstaller
						$version.AppendChild($location) | Out-Null
						$version.SetAttribute("name", $CurrentVersion)
						$SoftwareMaster.Save($SoftwareMasterFile)
					}
				}
				
				return $CurrentVersion, $False
			}					
		} ELSE {
			IF ($BitCount -eq "32")
			{
				$CurrentVersion = $Software.Versions32.version | Sort-Object $_.name -descending | Select-Object -First 1
				$CurrentVersion = $CurrentVersion.name
				IF (!(Test-Path $CurrentInstaller))
				{
					return $CurrentVersion, $True
				}
			} ELSEIF ($BitCount -eq "64") {
				$CurrentVersion = $Software.Versions64.version | Sort-Object $_.name -descending | Select-Object -First 1
				$CurrentVersion = $CurrentVersion.name
				IF (!(Test-Path $CurrentInstaller))
				{
					return $CurrentVersion, $True
				}
			}
			return $CurrentVersion, $False
		}		
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

Function Update-Software ($ArchiveOldVersions, $BitCount, $CurrentInstaller, $CurrentVersion, $HumanReadableName, $InstallerName, $LatestVersion, $LocalRepo, $Software, $SoftwareMaster, $SoftwareMasterFile, $templocation)
{
	IF ($CurrentInstaller -ne $Null)
	{
		IF ($CurrentVersion -eq $LatestVersion)
		{
			Write-Output "No New Version of $HumanReadableName $BitCount Bit Available`r`n"
			Start-Job -ScriptBlock {
				param($FileDelete)& {
					$Counter = 0
					WHILE (Test-Path $FileDelete -And $Counter -lt 13)
					{
						Remove-Item $FileDelete -Force -ErrorAction SilentlyContinue
						Start-Sleep 5
						$Counter++
					}
				}
			} -ArgumentList $templocation | out-null
		} ELSE {
			Write-Output "New Version of $HumanReadableName $BitCount Bit Available!`r`n"
		
			IF ($ArchiveOldVersions)
			{
				IF ($CurrentVersion -ne 0 -And $CurrentVersion -ne $Null)
				{
					$OldRepo = $LocalRepo + "\OldVersions"
					IF (!(Test-Path $OldRepo))
					{
						Try
						{
							New-Item $OldRepo -Type Directory -ErrorAction Stop | Out-Null
						} Catch {
							Write-Debug "Cannot create archive directory $OldRepo.
							Skipping Archive Process"
						}
					}
			
					$OldRepo = $OldRepo + "\" + $CurrentVersion
					Try
					{
						New-Item $OldRepo -Type Directory -ErrorAction Stop | Out-Null
					} Catch {
						Write-Debug "Cannot create archive directory $OldRepo.
						Skipping Archive Process"
					} Finally {
						Try
						{
							Copy-Item $CurrentInstaller $OldRepo -Force -ErrorAction Stop
						} Catch {
							Write-Debug "Cannot archive installer $CurrentInstaller.
							Skipping Archive Process"
						}
					}
					$ArchiveInstaller = $OldRepo + "\" + $InstallerName
					IF ($BitCount -eq "32")
					{
						$Version = $Software.Versions32.version | Where-Object { $_.name -eq $CurrentVersion }
					} ELSEIF ($BitCount -eq "64") {
						$Version = $Software.Versions64.version | Where-Object { $_.name -eq $CurrentVersion }
					}
					
					$Version.Location = $ArchiveInstaller
					$SoftwareMaster.Save($SoftwareMasterFile)
					Remove-Variable Version
				}
			}
		
			Try
			{
				Copy-Item $templocation $LocalRepo -Force -ErrorAction Stop
			} Catch {
				write-output "Could not copy new installer to $LocalRepo.
				Please ensure that this script has Write permissions to this location, and try again.`r`n"
			} Finally {
				write-output "$HumanReadableName $BitCount Bit updated to version $LatestVersion !`r`n"
			}
			Start-Job -ScriptBlock {
				param($FileDelete)& {
					$Counter = 0
					WHILE (Test-Path $FileDelete -And $Counter -lt 13)
					{
						Remove-Item $FileDelete -Force -ErrorAction SilentlyContinue
						Start-Sleep 5
						$Counter++
					}
				}
			} -ArgumentList $templocation | out-null
			
			$version = $SoftwareMaster.CreateElement("version")
			
			IF ($BitCount -eq "32")
			{
				IF (!($Software.Versions32))
				{
					$Versions = $SoftwareMaster.CreateElement("Versions32")
					$Software.AppendChild($Versions) | Out-Null
					$SoftwareMaster.Save($SoftwareMasterFile)
				} ELSE {
					$Versions = $Software.Versions32
				}
			} ELSEIF ($BitCount -eq "64") {
				IF (!($Software.Versions64))
				{
					$Versions = $SoftwareMaster.CreateElement("Versions64")
					$Software.AppendChild($Versions) | Out-Null
					$SoftwareMaster.Save($SoftwareMasterFile)
				} ELSE {
					$Versions = $Software.Versions64
				}
			}
			
			$Versions.AppendChild($version) | Out-Null
			$version.SetAttribute("name", $LatestVersion)
			$location = $SoftwareMaster.CreateElement("Location")
			$location.InnerText = $CurrentInstaller
			$version.AppendChild($location) | Out-Null
			$SoftwareMaster.Save($SoftwareMasterFile)		
		}
	}
}

$WebClient = New-Object System.Net.WebClient

IF ($DebugEnable)
{
	$DebugPreference = "Continue"
}

#Running portion of script

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
		Remove-Variable Package
		Continue
	}
	IF (($Package.SelectNodes("//Verify") | Where-Object { $_.InnerText -eq "USUS XML Package File" -And $_.InnerText -ne $Null}) -eq $Null)
	{
		Write-Debug "Package $UnimportedPackage doesn't seem to be valid, skipping..."
		Remove-Variable Package
		Continue
	}
	
	$PackageName = $Package.package.Name
	
	IF (($PackageMaster.Packages.Package | Where-Object { $_.Name -eq $PackageName }).Count -ne 0)
	{
		$CurrentPackage = $PackageMaster.Packages.Package | Where-Object { $_.Name -eq $PackageName } | Select-Object
		
		[int]$CurrentVersion = $CurrentPackage.Version
		[int]$LatestVersion = $Package.package.Version
		
		IF ($CurrentVersion -ge $LatestVersion)
		{
			Write-Debug "Package $UnimportedPackage already exists in Package Master, skipping..."
			Remove-Variable CurrentPackage
			Remove-Variable CurrentVersion
			Remove-Variable LatestVersion
			Remove-Variable Package
			Continue
		} ELSEIF ($CurrentVersion -lt $LatestVersion) {
			$CurrentPackage.ParentNode.RemoveChild($CurrentPackage) | Out-Null
			$HumanReadableName = $Package.package.HumanReadableName
			Write-Output "`r`n`r`n$HumanReadableName Package XML Updated to Version $LatestVersion"
			Remove-Variable CurrentPackage
			Remove-Variable CurrentVersion
			Remove-Variable HumanReadableName
			Remove-Variable LatestVersion
		}
	}
	
	$PackageMaster.Packages.AppendChild($PackageMaster.ImportNode($Package.Package,$true)) | Out-Null
	Remove-Item $UnimportedPackage
	$PackageMaster.Save($PackageMasterFile)
	
	Remove-Variable Package
}

$SoftwareMasterFile = $Configuration.config.softwarerepo.TrimEnd("\") + "\SoftwareMaster.xml"
IF (!(Test-Path $SoftwareMasterFile))
{
	$SoftwareMaster = New-Object System.Xml.XmlDocument
	$Software = $SoftwareMaster.CreateElement("SoftwarePackages")
	$SoftwareMaster.AppendChild($Software) | Out-Null
	$Software.AppendChild($SoftwareMaster.CreateElement("NullSoftware")) | Out-Null
	$SoftwareMaster.Save($SoftwareMasterFile)
	Remove-Variable SoftwareMaster
}

#Cleanup before running

IF ($PackageMaster)
{
	Remove-Variable PackageMaster
}
IF ($SoftwareMaster)
{
	Remove-Variable SoftwareMaster
}

[xml]$PackageMaster = Get-Content $PackageMasterFile
[xml]$SoftwareMaster = Get-Content $SoftwareMasterFile

IF ($Configuration.config.ArchiveOldVersions)
{
	$ArchiveOldVersions = $True
} ELSE {
	$ArchiveOldVersions = $False
}

Write-Output "`r`n`r`n"

ForEach ($Package in $PackageMaster.Packages.Package)
{	
	$PackageName = $Package.Name
	
	IF (!(($SoftwareMaster.SoftwarePackages.software | Where-Object { $_.Name -eq $PackageName }).Count -ne 0))
	{
		$Software = $SoftwareMaster.CreateElement("software")
		$SoftwareMaster.SoftwarePackages.AppendChild($Software) | Out-Null
		$Software.AppendChild($SoftwareMaster.CreateElement("Name")) | Out-Null
		$Software.Name = $PackageName
		$SoftwareMaster.Save($SoftwareMasterFile)
	} ELSE {
		$Software = $SoftwareMaster.SoftwarePackages.software | Where-Object { $_.Name -eq $PackageName }
	}
	
	IF ($Package.CustomPath)
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
	
	$LocalRepo = $LocalRepo + "\" + $Package.Name
	
	IF (!(Test-Path $LocalRepo))
	{
		Try
		{
			New-Item $LocalRepo -Type Directory -ErrorAction Stop | Out-Null
		} Catch {
			Write-Output "Could not create program directory of $LocalRepo.
Please ensure that this script has Write permissions to this location, and try again.`r`n"
		} 
	}
		
	$CurrentInstaller = $LocalRepo + "\" + $Package.Name
	$HumanReadableName = $Package.HumanReadableName
	
	IF ($Package.DownloadURL32 -Or $Package.URLGenerator32)
	{
		
		$CurrentInstaller32 = $CurrentInstaller + "-x32"
		$InstallerName32 = $Package.Name + "-x32"
		$templocation32 = $env:TEMP + "\" + $Package.Name + "-x32"
		IF ($Package.IsMSI)
		{
			$CurrentInstaller32 = $CurrentInstaller32 + ".msi"
			$InstallerName32 = $InstallerName32 + ".msi"
			$templocation32 = $templocation32 + ".msi"
			
		} ELSE {
			$CurrentInstaller32 = $CurrentInstaller32 + ".exe"
			$InstallerName32 = $InstallerName32 + ".exe"
			$templocation32 = $templocation32 + ".exe"
		}
		
		$GetSoftwareVersionResults = Get-SoftwareVersion -BitCount "32" -CurrentInstaller $CurrentInstaller32 -Package $Package -Software $Software
		IF ($GetSoftwareVersionResults -like "Error*" -Or $GetSoftwareVersionResults -like "Exception*")
		{
			Write-Debug $GetSoftwareVersionResults
			$CurrentVersion = "0"
			$ForceDownload = $True
		} ELSE {
			$CurrentVersion = $GetSoftwareVersionResults[0]
			$ForceDownload = $GetSoftwareVersionResults[1]
		}
		
		$GenerateURLResults = Generate-URL -BitCount "32" -CurrentVersion $CurrentVersion -Package $Package -WebClient $WebClient
		$DownloadURL = $GenerateURLResults[0]
		IF ($GenerateURLResults[1] -eq "No Version Retrieved") {
			$LatestVersion = "This should never match anything ever. Period. If it does, someone has gone HORRIBLY wrong in their versioning scheme. Hit Them."
			$LatestVersion = $Null
		} ELSE {
			$LatestVersion = $GenerateURLResults[1]
		}
		
		IF ($ForceDownload)
		{
			$LatestVersion = $Null
		}
		
		$LatestVersion = Get-LatestInstaller -CurrentVersion $CurentVersion -DownloadURL $DownloadURL -LatestVersion $LatestVersion -Package $Package -templocation $templocation32
		
		IF ($LatestVersion -eq "This should never match anything ever. Period. If it does, someone has gone HORRIBLY wrong in their versioning scheme. Hit Them.")
		{
			Write-Debug "Wow. I mean WOW! Please find this developer and hit them. HARD. Their version string was actually 'This should never match anything ever. Period. If it does, someone has gone HORRIBLY wrong in their versioning scheme. Hit Them.'. There are no words."
		}
		
		Update-Software -ArchiveOldVersions $ArchiveOldVersions -BitCount "32" -CurrentInstaller $CurrentInstaller32 -CurrentVersion $CurrentVersion -HumanReadableName $HumanReadableName -InstallerName $InstallerName32 -LatestVersion $LatestVersion -LocalRepo $LocalRepo -Software $Software -SoftwareMaster $SoftwareMaster -SoftwareMasterFile $SoftwareMasterFile -templocation $templocation32
		
	}
	
	IF ($Package.DownloadURL64 -Or $Package.URLGenerator64)
	{
		
		$CurrentInstaller64 = $CurrentInstaller + "-x64"
		$InstallerName64 = $Package.Name + "-x64"
		$templocation64 = $env:TEMP + "\" + $Package.Name + "-x64"
		IF ($Package.IsMSI)
		{
			$CurrentInstaller64 = $CurrentInstaller64 + ".msi"
			$InstallerName64 = $InstallerName64 + ".msi"
			$templocation64 = $templocation64 + ".msi"
			
		} ELSE {
			$CurrentInstaller64 = $CurrentInstaller64 + ".exe"
			$InstallerName64 = $InstallerName64 + ".exe"
			$templocation64 = $templocation64 + ".exe"
		}
		
		$GetSoftwareVersionResults = Get-SoftwareVersion -BitCount "64" -CurrentInstaller $CurrentInstaller64 -Package $Package -Software $Software
		$CurrentVersion = $GetSoftwareVersionResults[0]
		$ForceDownload = $GetSoftwareVersionResults[1]
		
		$GenerateURLResults = Generate-URL -BitCount "64" -CurrentVersion $CurrentVersion -Package $Package -WebClient $WebClient
		$DownloadURL = $GenerateURLResults[0]
		IF ($GenerateURLResults[1] -eq "No Version Retrieved") {
			$LatestVersion = "This should never match anything ever. Period. If it does, someone has gone HORRIBLY wrong in their versioning scheme. Hit Them."
			$LatestVersion = $Null
		} ELSE {
			$LatestVersion = $GenerateURLResults[1]
		}
		
		IF ($ForceDownload)
		{
			$LatestVersion = $Null
		}
		
		$LatestVersion = Get-LatestInstaller -CurrentVersion $CurentVersion -DownloadURL $DownloadURL -ForceDownload $ForceDownload -LatestVersion $LatestVersion -Package $Package -templocation $templocation64
		
		IF ($LatestVersion -eq "This should never match anything ever. Period. If it does, someone has gone HORRIBLY wrong in their versioning scheme. Hit Them.")
		{
			Write-Debug "Wow. I mean WOW! Please find this developer and hit them. HARD. Their version string was actually 'This should never match anything ever. Period. If it does, someone has gone HORRIBLY wrong in their versioning scheme. Hit Them.'. There are no words."
		}
		
		Update-Software -ArchiveOldVersions $ArchiveOldVersions -BitCount "64" -CurrentInstaller $CurrentInstaller64 -CurrentVersion $CurrentVersion -HumanReadableName $HumanReadableName -InstallerName $InstallerName64 -LatestVersion $LatestVersion -LocalRepo $LocalRepo -Software $Software -SoftwareMaster $SoftwareMaster -SoftwareMasterFile $SoftwareMasterFile -templocation $templocation64
		
	}	
}

#Cleanup Package and Software Master Files

#End
