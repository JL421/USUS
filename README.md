##What is this?

USUS (Ultimate Software Update Script) is a Windows Powershell Script (v3.0+) that will check for updated installers for just about any installer. If you give it a set of packages to run with, it'll make sure your Installers are on the latest version, and make a useful XML file with all the info any add-on scripts need to make deployment packages.

-----

##Why Should I Use This Instead Of...?

USUS gives you more control over what you bring into your environment, while allowing you to make sure you always have the latest patches available.

 * You don't have to worry about what code could be hidden inside of a download script
   - The source code of USUS is freely available, and USUS Packages can be verified before placing into service. You can even create your own packages. (Verification for installers downloaded with the script coming soon)

 * You don't have to replace your current deployment method
   - USUS add-on scripts can integrate with multiple deployment options (Chocolatey currently available with more coming soon).

 * It doesn't cost you anything
   - Though donations or submitting USUS packages/USUS Add On scripts  to /r/USUScript are appreciated.

-----

##Screenshots

[Run with Updates](http://i.imgur.com/LrurV35.png)

-----

##Current Features
**v2.0** (2015-10-01)

 - XML input files
* Imports Package XML documents into a Master XML containing all packages
 - XML output file
* One Master XML document containing all information about all software packages, and versions
 - Version Management (And cleanup)
 - Add-on script for [Chocolatey packages](https://raw.githubusercontent.com/JL421/USUS-AddOns/master/USUS-Chocolatey.ps1) available, with more coming soon
 - More stable codebase
* USUS itself shouldn't have to be updated to add new packaging functionality
* With fewer actions happening inside USUS, there are fewer opportunities for things to break
 - Actual 32 and 64 bit management
* USUS now has multiple versions inside single package files, and stores all the metadata for software, together

-----

##Upgrade Notes

USUS 2.0 is extremely different from previous versions, read the following carefully to complete the upgrade

 - Config File Changes:
* If you remove the ArchiveOldVersions node, and have a current archive, it will be cleared out. However, pre-existing archives will not have their metadata cataloged saved.

The config file is now only 5 lines of XML:

    <config>
      <SoftwareRepo>PathtoSoftwareRepo</SoftwareRepo> <!-- Where you want your Software Stored -->
      <PackagesRepo>PathtoPackageRepo</PackagesRepo> <!-- Where you want your Packages Kept -->
      <ArchiveOldVersions>True</ArchiveOldVersions> <!-- Delete or comment this line if you don't want to Archive Installers -->
    </config>

 - New USUS package files must be downloaded or created and placed in the Packages Repo folder.
 - There is currently no email reporting functionality, this will be added soon in an Add-On Script
 - Powershell v3 or above is required for proper functionality


-----

##Download

 * [USUS @ Github](https://github.com/JL421/USUS) - [PS1](https://raw.githubusercontent.com/JL421/USUS/master/USUS.ps1)
 * [USUS @ USUScript.com](https://www.ususcript.com/download/6/)
 * [Packages @ Github](https://github.com/JL421/USUS-Packages)

-----

##Running the Script

 - Run the script from command line, or create a scheduled task to keep your installers up to date automatically.

        Usage: USUS.ps1 -ConfigFile [Your ConfigFile Path]

        Required Flags :
         -ConfigFile    This is the path to your Config File XML Document
  
        Optional Flags :
            -DebugEnable  Use this to enable Debug output


As of now, the script is unsigned, this may change in the future, depending on if it's a big request.

As a result, there are two ways to run the script:

1. **Recommended** : `Powershell.exe -ExecutionPolicy Bypass -NoProfile -File [Path to Script] -ConfigDir [Path to Config Directory]`
 * This runs only the script in Bypass mode, bypassing the need for a signed script, but still preventing other unsigned scripts from running.
2. Globally setting Powershell's Execution Policy to Bypass.
 * **Highly Unrecommended**

-----

## Adding/Modifying Packages

Adding Packages is easy, either create one from the Template [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/Template.xml) - [USUScript.com](https://www.ususcript.com/download/10/), or grab one from the community. Then just place it into your Config\Packages Directory.

-----
##Pre-Built Packages

  * 7 zip Bit (EXE Beta) - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/7Zip.EXE.beta.xml) - [USUScript.com](https://www.ususcript.com/download/26/) 
  * Adobe Air - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/AdobeAir.EXE.xml) - [USUScript.com](https://www.ususcript.com/download/28/)
  * Adobe Reader - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/AdobeReader.MSI.xml) - [USUScript.com](https://www.ususcript.com/download/30/)
  * CrashPlan Pro - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/CrashPlanPro.EXE.xml) - [USUScript.com](https://www.ususcript.com/download/32/)
  * FileZilla - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/FileZilla.EXE.xml) - [USUScript.com](https://www.ususcript.com/download/36/)
  * Firefox - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/FireFox.EXE.xml) - [USUScript.com](https://www.ususcript.com/download/38/)
  * Firefox ESR - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/FireFox.ESR.EXE.xml) - [USUScript.com](https://www.ususcript.com/download/34/) - /u/Cyrandir
  * Flash Player (Firefox MSI) - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/FlashPlayer.FireFox.MSI.xml) - [USUScript.com](https://www.ususcript.com/download/40/)
  * Flash Player (IE MSI) - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/FlashPlayer.IE.MSI.xml) - [USUScript.com](https://www.ususcript.com/download/42/)
  * Google Chrome (MSI) - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/GoogleChrome.MSI.xml) - [USUScript.com](https://www.ususcript.com/download/44/)
  * Shockwave (MSI) - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/Shockwave.MSI.xml) - [USUScript.com](https://www.ususcript.com/download/46/) -  /u/Cyrandir
  * Skype (MSI) - [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/Skype.MSI.xml) - [USUScript.com](https://www.ususcript.com/download/48/) - /u/Cyrandir
  * VLC Player- [GitHub](https://raw.githubusercontent.com/JL421/USUS-Packages/master/VLC.EXE.xml) - [USUScript.com](https://www.ususcript.com/download/50/)


-----
##Add On Scripts
   * USUS to Chocolatey - [GitHub](https://raw.githubusercontent.com/JL421/USUS-AddOns/master/USUS-Chocolatey.ps1) - [USUScript.com](https://www.ususcript.com/download/52/)

-----

##Planned Changes

 * Installer Verification
 * Self Update - Optionally Self Update USUS

-----

##Change Log

**v2.0** (2015-10-01)

 - Major Overhaul
 - XML input files
* Imports Package XML documents into a Master XML containing all packages
 - XML output file
* One Master XML document containing all information about all software packages, and versions
 - Version Management (And cleanup)
 - Add-on script for [Chocolatey packages](https://raw.githubusercontent.com/JL421/USUS-AddOns/master/USUS-Chocolatey.ps1) available, with more coming soon
 - More stable codebase
* USUS itself shouldn't have to be updated to add new packaging functionality
* With fewer actions happening inside USUS, there are fewer opportunities for things to break
 - Actual 32 and 64 bit management
* USUS now has multiple versions inside single package files, and stores all the metadata for software, together

**v1.5** (2015-07-08)

 - Added Chocolatey Package Support with Versioning
 - Allowed the Config Dir to be imported from -ConfigDir when using -InitialSetup
 - Miscellaneous Tweaking to various code

**v1.4** (2015-07-06)

 - Added Assisted Setup
 - Added option to only send emails on new updates

**v1.3** (2015-04-21)

 - Improved Email Reporting
 - Archiving for Old Installers
 - Readded Custom Locations
 - Custom Descriptions for Deployment Packages
 - Removed Transcripts
 - Misc bug fixes

**v1.2** (2015-04-13)

 - Added Deployment Package Creation
 - Bug Fixes

**v1.1** (2015-04-09)

 - Cleaned up the Main Script body by moving Functions and Packages to a Config Directory
 - Made some improvements to Bandwidth Usage
 - Added Change Log and Current Version Logs to the SoftwareRepo Directory
 - Added Email Reporting

-----

##Community Package Sharing / Feature Requests / New Releases

You can find all of this at /r/USUScript

Shared Packages that test well will be included in the Git Repository, with credit to the creator.

Feature Requests will be worked on as time or necessity allows.

The latest releases and fixes will be announced here as well, with Major Releases/Fixes also released posted on /r/sysadmin.
