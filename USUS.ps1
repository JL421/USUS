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

#Functions

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

$WebClient = New-Object System.Net.WebClient

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
		Continue
	}
	IF (($Package.SelectNodes("//Verify") | Where-Object { $_.InnerText -eq "USUS XML Package File" -And $_.InnerText -ne $Null}) -eq $Null)
	{
		Write-Debug "Package $UnimportedPackage doesn't seem to be valid, skipping..."
		Continue
	}
	
	$PackageName = $Package.package.Name
	
	IF (($PackageMaster.SelectNodes("//Packages/package") | Where-Object { $_.Name -eq $PackageName }).Count -ne 0)
	{
		Write-Debug "Package $UnimportedPackage already exists in Package Master, skipping..."
		Continue
	}
	$PackageMaster.Packages.AppendChild($PackageMaster.ImportNode($Package.Package,$true)) | Out-Null
	Remove-Item $UnimportedPackage
	$PackageMaster.Save($PackageMasterFile)
	$Restart = $True
}

IF ($Restart -eq $True)
{
	Write-Output "`r`n`r`nImported new Packages, please run script again to process.`r`n"
	Exit
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

[xml]$PackageMaster = Get-Content $PackageMasterFile
[xml]$SoftwareMaster = Get-Content $SoftwareMasterFile

Write-Output "`r`n`r`n"

ForEach ($Package in $PackageMaster.Packages.Package)
{	
	$PackageName = $Package.Name
	
	IF (!(($SoftwareMaster.SelectNodes("//SoftwarePackages/software/Name[text() = '$PackageName']")).Count -ne 0))
	{
		$Software = $SoftwareMaster.CreateElement("software")
		$SoftwareMaster.SoftwarePackages.AppendChild($Software) | Out-Null
		$Software.AppendChild($SoftwareMaster.CreateElement("Name")) | Out-Null
		$Software.Name = $PackageName
		$SoftwareMaster.Save($SoftwareMasterFile)
	} ELSE {
		$Software = $SoftwareMaster.SelectNodes("//SoftwarePackages/software") | Where-Object { $_.Name -eq $PackageName }
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
	}
	
	#Get Current 32 Bit Version
	IF ($Package.DownloadURL32 -Or $Package.URLGenerator32)
	{
		IF (!($Software.Versions32))
		{			
			IF ($Package.IsMSI)
			{
				IF ($CurrentInstaller32)
				{
					IF (!(Test-Path $CurrentInstaller32))
					{
						$CurrentVersion32 = "0"
					} ELSE {
						[string]$CurrentVersion32 = MSI-Version $CurrentInstaller32
						$CurrentVersion32 = $CurrentVersion32.Trim()
						
						IF (!($Software.Versions32))
						{
							$Versions32 = $SoftwareMaster.CreateElement("Versions32")
							$Software.AppendChild($Versions32) | Out-Null
							$SoftwareMaster.Save($SoftwareMasterFile)
						} ELSE {
							$Versions32 = $Software.Versions32
						}
						$version = $SoftwareMaster.CreateElement("version")
						$Versions32.AppendChild($version) | Out-Null
						$version.SetAttribute("name", $CurrentVersion32)
						$SoftwareMaster.Save($SoftwareMasterFile)
					}
				}
			} ELSE {
				IF ($CurrentInstaller32)
				{
					IF (!(Test-Path $CurrentInstaller32))
					{
						$CurrentVersion32 = "0"
					} ELSE {
						[string]$CurrentVersion32 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($CurrentInstaller32).FileVersion
						$CurrentVersion32 = $CurrentVersion32.Trim()
						IF ($CurrentVersion32 -eq $Null -Or $CurrentVersion32 -eq "")
						{
							$CurrentVersion32 = (Get-Item $CurrentInstaller32).Length
						} ELSE {
							IF (!($Software.Versions32))
							{
								$Versions32 = $SoftwareMaster.CreateElement("Versions32")
								$Software.AppendChild($Versions32) | Out-Null
								$SoftwareMaster.Save($SoftwareMasterFile)
							} ELSE {
								$Versions32 = $Software.Versions32
							}
							$version = $SoftwareMaster.CreateElement("version")
							$Versions32.AppendChild($version) | Out-Null
							$version.SetAttribute("name", $CurrentVersion32)
							$SoftwareMaster.Save($SoftwareMasterFile)
						}
					}
				}					
			}
		} ELSE {
			IF ($CurrentInstaller32)
			{
				$CurrentVersion32 = $Software.Versions64.version | Sort-Object $_.name -descending | Select-Object -First 1
				$CurrentVersion32 = $CurrentVersion32.name
				IF (!(Test-Path $CurrentInstaller32))
				{
					$ForceDownload32 = $True
				}
			}		
		}
	}
	
	#Get Current 64 Bit Version
	
	IF ($Package.DownloadURL64 -Or $Package.URLGenerator64)
	{
		IF (!($Software.Versions64))
		{
			IF ($Package.IsMSI)
			{
				Write-Output $Package.IsMSI
				Write-Output Test
				IF ($CurrentInstaller64)
				{
					IF (!(Test-Path $CurrentInstaller64))
					{
						$CurrentVersion64 = "0"
					} ELSE {
						[string]$CurrentVersion64 = MSI-Version $CurrentInstaller64
						$CurrentVersion64 = $CurrentVersion64.Trim()
						
						IF (!($Software.Versions64))
						{
							$Versions64 = $SoftwareMaster.CreateElement("Versions64")
							$Software.AppendChild($Versions64) | Out-Null
							$SoftwareMaster.Save($SoftwareMasterFile)
						} ELSE {
							$Versions64 = $Software.Versions64
						}
						$version = $SoftwareMaster.CreateElement("version")
						$Versions64.AppendChild($version) | Out-Null
						$version.SetAttribute("name", $CurrentVersion64)
						$SoftwareMaster.Save($SoftwareMasterFile)
					}
				}
			} ELSE {
				IF ($CurrentInstaller64)
				{
					IF (!(Test-Path $CurrentInstaller64))
					{
						$CurrentVersion64 = "0"
					} ELSE {
						[string]$CurrentVersion64 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($CurrentInstaller64).FileVersion
						$CurrentVersion64 = $CurrentVersion64.Trim()
						IF ($CurrentVersion64 -eq $Null -Or $CurrentVersion64 -eq "")
						{
							$CurrentVersion64 = (Get-Item $CurrentInstaller64).Length
						} ELSE {
							IF (!($Software.Versions64))
							{
								$Versions64 = $SoftwareMaster.CreateElement("Versions64")
								$Software.AppendChild($Versions64) | Out-Null
								$SoftwareMaster.Save($SoftwareMasterFile)
							} ELSE {
								$Versions64 = $Software.Versions64
							}
							$version = $SoftwareMaster.CreateElement("version")
							$Versions64.AppendChild($version) | Out-Null
							$version.SetAttribute("name", $CurrentVersion64)
							$SoftwareMaster.Save($SoftwareMasterFile)
						}
					}
				}					
			}
		} ELSE {
			IF ($CurrentInstaller64)
			{
				$CurrentVersion64 = $Software.Versions64.version | Sort-Object $_.name -descending | Select-Object -First 1
				$CurrentVersion64 = $CurrentVersion64.name
				IF (!(Test-Path $CurrentInstaller64))
				{
					$ForceDownload64 = $True
				}
			}		
		}
	}
	
	IF (!($Package.DownloadURL32))
	{
		IF (($Package.URLGenerator32.URLGenerator).Count -ne 0)
		{
			$URLGenerator = ""
			$Package.URLGenerator32.URLGenerator | ForEach {
				$URLGenerator = $URLGenerator + "`r`n" + $_
			}
			$URLGenerator = [scriptblock]::Create($URLGenerator)
			$VersionURL = Invoke-Command -scriptblock {param($CurrentVersion32, $WebClient)& $URLGenerator} -ArgumentList $CurrentVersion32,$WebClient
			IF (!($VersionURL -like "Error*") -Or !($VersionURL -like "Exception*"))
			{
				IF ($VersionURL.Count -eq 2)
				{
					$DownloadURL32 = $VersionURL[0]
					[string]$LatestVersion32 = $VersionURL[1]
					$LatestVersion32 = $LatestVersion32.Trim()
				} ELSEIF ($VersionURL -ne $Null) {
					$DownloadURL32 = $VersionURL
				}
			} ELSE {
			
				Write-Debug "Error occurred while retrieving URL for package $PackageName
				The error was $VersionURL"
				Continue
			}
		}
	} ELSE {
		$DownloadURL32 = $Package.DownloadURL32
	}
	
	IF (!($Package.DownloadURL64))
	{
		IF (($Package.URLGenerator64.URLGenerator).Count -ne 0)
		{
			$URLGenerator = ""
			$Package.URLGenerator64.URLGenerator | ForEach {
				$URLGenerator = $URLGenerator + "`r`n" + $_
			}
			$URLGenerator = [scriptblock]::Create($URLGenerator)
			$VersionURL = Invoke-Command -scriptblock {param($CurrentVersion64, $WebClient)& $URLGenerator} -ArgumentList $CurrentVersion64,$WebClient
			IF (!($VersionURL -like "Error*"))
			{
				IF ($VersionURL.Count -eq 2)
				{
					$DownloadURL64 = $VersionURL[0]
					[string]$LatestVersion64 = $VersionURL[1]
					$LatestVersion64 = $LatestVersion64.Trim()
				} ELSEIF ($VersionURL -ne $Null) {
					$DownloadURL64 = $VersionURL
				}
			} ELSE {
			
				Write-Debug "Error occurred while retrieving URL for package $PackageName
				The error was $VersionURL"
				Continue
			}
		}
	} ELSE {
		$DownloadURL64 = $Package.DownloadURL64
	}
	
	#Get New Installer if Necessary
	
	IF ($ForceDownload32)
	{
		$CurrentVersion32 = $Null
		IF ($LatestVersion32 -eq $Null)
		{
			$LatestVersion32 = "1"
		}
	}
	
	IF ($ForceDownload64)
	{
		$CurrentVersion64 = $Null
		IF ($LatestVersion64 -eq $Null)
		{
			$LatestVersion64 = "1"
		}
	}
	
	IF ($Package.IsMSI)
	{	
		IF ($DownloadURL32 -ne $Null)
		{
			IF ($LatestVersion32 -eq $Null -Or (!($LatestVersion32)))
			{
				$LatestVersion32 = $CurrentVersion32
				Get-NewInstaller $DownloadURL32 $templocation32
				[string]$LatestVersion32 = MSI-Version $templocation32
				$LatestVersion32 = $LatestVersion32.Trim()
			} ELSE {
				IF ($CurrentVersion32 -ne $LatestVersion32)
				{
					Get-NewInstaller $DownloadURL32 $templocation32
					IF ($ForceDownload32)
					{
						[string]$LatestVersion32 = MSI-Version $templocation32
						$LatestVersion32 = $LatestVersion32.Trim()
					}
				}
			}
		}
		
		IF ($DownloadURL64 -ne $Null)
		{
			IF ($LatestVersion64 -eq $Null -Or (!($LatestVersion64)))
			{
				$LatestVersion64 = $CurrentVersion64
				Get-NewInstaller $DownloadURL64 $templocation64
				[string]$LatestVersion64 = MSI-Version $templocation64
				$LatestVersion64 = $LatestVersion64.Trim()
			} ELSE {
				IF ($CurrentVersion64 -ne $LatestVersion64)
				{
					Get-NewInstaller $DownloadURL64 $templocation64
					IF ($ForceDownload64)
					{
						[string]$LatestVersion64 = MSI-Version $templocation64
						$LatestVersion64 = $LatestVersion64.Trim()
					}
				}
			}
		}
	} ELSE {
		IF ($DownloadURL32)
		{
			IF ($LatestVersion32 -eq $Null -Or (!($LatestVersion32)))
			{
				$LatestVersion32 = $CurrentVersion32				
				Get-NewInstaller $DownloadURL32 $templocation32
				[string]$LatestVersion32 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($templocation32).FileVersion
				$LatestVersion32 = $LatestVersion32.Trim()
				IF ($LatestVersion32 -eq $Null -Or $LatestVersion32 -eq "")
				{
					$LatestVersion32 = (Get-Item $templocation32).Length
					$LatestVersion32 = $LatestVersion32.Trim()
					$NoVersion = $True
				}
			} ELSE {
				IF ($CurrentVersion32 -ne $LatestVersion32)
				{
					Get-NewInstaller $DownloadURL32 $templocation32
					IF ($ForceDownload32)
					{
						[string]$LatestVersion32 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($templocation32).FileVersion
						$LatestVersion32 = $LatestVersion32.Trim()
					}
				}
			}
		}
		
		IF ($DownloadURL64)
		{
			IF ($LatestVersion64 -eq $Null -Or (!($LatestVersion64)))
			{
				$LatestVersion64 = $CurrentVersion64
				Get-NewInstaller $DownloadURL64 $templocation64
				[string]$LatestVersion64 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($templocation64).FileVersion
				$LatestVersion64 = $LatestVersion64.Trim()
				IF ($LatestVersion64 -eq $Null -Or $LatestVersion64 -eq "")
				{
					$LatestVersion64 = (Get-Item $templocation64).Length
					$LatestVersion64 = $LatestVersion64.Trim()
					$NoVersion = $True
				}
			} ELSE {
				IF ($CurrentVersion64 -ne $LatestVersion64)
				{
					Get-NewInstaller $DownloadURL64 $templocation64
					IF ($ForceDownload64)
					{
						[string]$LatestVersion64 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($templocation64).FileVersion
						$LatestVersion64 = $LatestVersion64.Trim()
					}
				}
			}
		}
	}
	
	$HumanReadableName = $Package.HumanReadableName
	
	IF ($CurrentInstaller32 -ne $Null)
	{
		IF ($CurrentVersion32 -eq $LatestVersion32)
		{
			Write-Output "No New Version of $HumanReadableName 32 Bit Available`r`n"
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
			} -ArgumentList $templocation32 | out-null
		} ELSE {
			Write-Output "New Version of $HumanReadableName 32 Bit Available!`r`n"
		
			IF ($Configuration.config.ArchiveOldVersions)
			{
				IF ($CurrentVersion32 -ne 0 -And $CurrentVersion32 -ne $Null)
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
			
					$OldRepo = $OldRepo + "\" + $CurrentVersion32
					Try
					{
						New-Item $OldRepo -Type Directory -ErrorAction Stop | Out-Null
					} Catch {
						Write-Debug "Cannot create archive directory $OldRepo.
						Skipping Archive Process"
					} Finally {
						Try
						{
							Copy-Item $CurrentInstaller32 $OldRepo -Force -ErrorAction Stop
						} Catch {
							Write-Debug "Cannot archive installer $CurrentInstaller32.
							Skipping Archive Process"
						}
					}
					$ArchiveInstaller32 = $OldRepo + "\" + $InstallerName32
					$Version32 = $Software.Versions32.version | Where-Object { $_.name -eq $CurrentVersion32 }
					$Version32.Location = $ArchiveInstaller32
					$SoftwareMaster.Save($SoftwareMasterFile)
					Remove-Variable Version32
				}
			}
		
			Try
			{
				Copy-Item $templocation32 $LocalRepo -Force -ErrorAction Stop
			} Catch {
				write-output "Could not copy new installer to $LocalRepo.
				Please ensure that this script has Write permissions to this location, and try again.`r`n"
			} Finally {
				write-output "$HumanReadableName 32 Bit updated to version $LatestVersion32!`r`n"
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
			} -ArgumentList $templocation32 | out-null
			
			$version = $SoftwareMaster.CreateElement("version")
			
			IF (!($Software.Versions32))
			{
				$Versions32 = $SoftwareMaster.CreateElement("Versions32")
				$Software.AppendChild($Versions32) | Out-Null
				$SoftwareMaster.Save($SoftwareMasterFile)
			} ELSE {
				$Versions32 = $Software.Versions32
			}
			
			$Versions32.AppendChild($version) | Out-Null
			$version.SetAttribute("name", $LatestVersion32)
			$location = $SoftwareMaster.CreateElement("Location")
			$location.InnerText = $CurrentInstaller32
			$version.AppendChild($location) | Out-Null
			$SoftwareMaster.Save($SoftwareMasterFile)		
		}
	}
	
	IF ($CurrentInstaller64 -ne $Null)
	{
		IF ($CurrentVersion64 -eq $LatestVersion64)
		{
			Write-Output "No New Version of $HumanReadableName 64 Bit Available`r`n"
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
			} -ArgumentList $templocation64 | out-null
		} ELSE {
			Write-Output "New Version of $HumanReadableName 64 Bit Available!`r`n"
		
			IF ($Configuration.config.ArchiveOldVersions)
			{
				IF ($CurrentVersion64 -ne 0 -And $CurrentVersion64 -ne $Null)
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
			
					$OldRepo = $OldRepo + "\" + $CurrentVersion64
					Try
					{
						New-Item $OldRepo -Type Directory -ErrorAction Stop | Out-Null
					} Catch {
						Write-Debug "Cannot create archive directory $OldRepo.
						Skipping Archive Process"
					} Finally {
						Try
						{
							Copy-Item $CurrentInstaller64 $OldRepo -Force -ErrorAction Stop
						} Catch {
							Write-Debug "Cannot archive installer $CurrentInstaller64.
							Skipping Archive Process"
						}
					}
					$ArchiveInstaller64 = $OldRepo + "\" + $InstallerName64
					$Version64 = $Software.Versions64.version | Where-Object { $_.name -eq $CurrentVersion64 }
					$Version64.Location = $ArchiveInstaller64
					$SoftwareMaster.Save($SoftwareMasterFile)
					Remove-Variable Version64
				}
			}
		
			Try
			{
				Copy-Item $templocation64 $LocalRepo -Force -ErrorAction Stop
			} Catch {
				write-output "Could not copy new installer to $LocalRepo.
				Please ensure that this script has Write permissions to this location, and try again.`r`n"
			} Finally {
				write-output "$HumanReadableName 64 Bit updated to version $LatestVersion64!`r`n"
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
			} -ArgumentList $templocation64 | out-null
			$version = $SoftwareMaster.CreateElement("version")
			
			IF (!($Software.Versions64))
			{
				$Versions64 = $SoftwareMaster.CreateElement("Versions64")
				$Software.AppendChild($Versions64) | Out-Null
				$SoftwareMaster.Save($SoftwareMasterFile)
			} ELSE {
				$Versions64 = $Software.Versions64
			}
			
			$Versions64.AppendChild($version) | Out-Null
			$version.SetAttribute("name", $LatestVersion64)
			$location = $SoftwareMaster.CreateElement("Location")
			$location.InnerText = $CurrentInstaller64
			$version.AppendChild($location) | Out-Null
			$SoftwareMaster.Save($SoftwareMasterFile)		
		}
	}
	
}

#Cleanup Package and Software Master Files

#End
