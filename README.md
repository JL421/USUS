##What is this?

USUS (Ultimate Software Update Script) is a Windows Powershell Script (v2.0+) that will check for updated installers for just about any installer. If you give it a set of packages to run with, it'll make sure your Installers are on the latest version, and package them up in a convenient format. (Batch, Chocolatey, Lansweeper, PDQ Deploy, Self-Extracting Installer)

-----

##Why Should I Use This Instead Of...?

USUS gives you more control over what you bring into your environment, while allowing you to make sure you always have the latest patches available.

 * You don't have to worry about what code could be hidden inside of a download script
   - The source code of USUS is freely available, and USUS Packages can be verified before placing into service. You can even create your own packages. (Verification for installers downloaded with the script coming soon)

 * You don't have to replace your current deployment method
   - USUS integrates with multiple deployment options (Batch files, Chocolatey, Lansweeper, PDQ Deploy), with support for automatic importation coming soon.

 * It doesn't cost you anything
   - Though donations or submitting USUS packages to /r/USUScript are appreciated.

-----

##Screenshots

[Run with Updates](http://i.imgur.com/7KfnWlH.png) | [Run Without Updates](http://i.imgur.com/XjbsUTO.png) | [Email Report Example](http://i.imgur.com/vug7Un3.png) | [Change Log Example](http://i.imgur.com/04r6Olc.png) | [Current Version Log Example](http://i.imgur.com/TqKnYPF.png)

-----

##Current Features
**v1.5** (2015-07-08)

 - Assisted Setup
 - Email Reporting
 - Version Management
 - Batch, Chocolatey, Lansweeper, PDQ, and Self Extracting Installer support

-----

##Upgrade Notes

 - Should be plug and play with v1.3+ - Use the -InitialSetup flag to update your Config
 - Delete your Config/Includes folder to fetch all required components automatically
 - Packages will be updated shortly to include new variables for Chocolatey Packages (Tags and WMI name)

-----

##Download

 * [USUS @ Github](https://github.com/JL421/USUS) - [Zip](https://github.com/JL421/USUS/archive/master.zip)
 * [USUS @ Mirror](https://www.jasonlorsung.com/download/114/)
 * [Packages @ Github](https://github.com/JL421/USUS-Packages)

-----

##Running the Script

 - Run the script from command line, and it will walk you through an initial setup

        powershell.exe -ExecutionPolicy Bypass -File "Path to USUS.ps1"

 - Run the script from command line, or create a scheduled task to keep your installers up to date automatically.

        Usage: USUS.ps1 -ConfigDir [Your ConfigDirectory Path] [-ForceDeploymentPackage] [-InitialSetup]

        Required Flags :
         -ConfigDir    This is where all of the parts of the script live.
        This currently contains the PackageRepo, IncludesDir, and Base Config
    
        Optional Flags :
         -ForceDeploymentPackage This flag forces Deployment Packages to be rebuilt on every run.
         -InitialSetup This flag reruns the assisted setup, for easy editing of Config files


As of now, the script is unsigned, this may change in the future, depending on if it's a big request.

As a result, there are two ways to run the script:

1. **Recommended** : `Powershell.exe -ExecutionPolicy Bypass -File [Path to Script] -ConfigDir [Path to Config Directory]`
 * This runs only the script in Bypass mode, bypassing the need for a signed script, but still preventing other unsigned scripts from running.
2. Globally setting Powershell's Execution Policy to Bypass.
 * **Highly Unrecommended**

-----

## Adding/Modifying Packages

Adding Packages is easy, either create one from the Template [GitHub](https://github.com/JL421/USUS-Packages/blob/master/Template.conf) - [Mirror](https://www.jasonlorsung.com/download/108/), or grab one from the community. Then just place it into your Config\Packages Directory.

-----
##Pre-Built Packages

  * 7 zip 32 Bit MSI - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/7Zip.conf) - [Mirror](https://www.jasonlorsung.com/download/81/) 
  * 7 zip 64 Bit MSI - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/7Zipx64.conf) - [Mirror](https://www.jasonlorsung.com/download/85/)
  * Adobe Air - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/AdobeAir.conf) - [Mirror](https://www.jasonlorsung.com/download/88/)
  * Adobe Reader - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/AdobeReader.conf) - [Mirror](https://www.jasonlorsung.com/download/90/)
  * FileZilla - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/FileZilla.conf) - [Mirror](https://www.jasonlorsung.com/download/92/)
  * Firefox - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/Firefox.conf) - [Mirror](https://www.jasonlorsung.com/download/94/)
  * Firefox ESR - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/FirefoxESR.conf) - [Mirror](https://www.jasonlorsung.com/download/96/) - /u/Cyrandir
  * Flash Player (Firefox) - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/FlashPlayer-Firefox.conf) - [Mirror](https://www.jasonlorsung.com/download/98/) - Must provide your own Distribution Link (http://www.adobe.com/products/players/flash-player-distribution.html)
  * Flash Player (IE) - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/FlashPlayer-IE.conf) - [Mirror](https://www.jasonlorsung.com/download/100/) - Must provide your own Distribution Link (http://www.adobe.com/products/players/flash-player-distribution.html)
  * Google Chrome 64 Bit MSI - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/GoogleChrome-x64MSI.conf) - [Mirror](https://www.jasonlorsung.com/download/102/)
  * Shockwave MSI - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/Shockwave.conf) - [Mirror](https://www.jasonlorsung.com/download/104/) -  /u/Cyrandir
  * Skype MSI - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/Skype.conf) - [Mirror](https://www.jasonlorsung.com/download/106/) - /u/Cyrandir
  * VLC 32 Bit - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/VLC.conf) - [Mirror](https://www.jasonlorsung.com/download/110/)
  * VLC 64 Bit - [GitHub](https://github.com/JL421/USUS-Packages/blob/master/VLCx64.conf) - [Mirror](https://www.jasonlorsung.com/download/112/)


-----

##Planned Changes

 * Better Email Reports
 * Installer Verification
 * Deeper integration with Deployment Software
 * Self Update - Optionally Self Update USUS
 * SCCM Packages

-----

##Change Log

**v1.5** (2015-07-08

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

-----

Donations: `15zpLkRwSUtUDDcuGAh7pqV6P6rrAoXqCp`
