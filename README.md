# USUS
The Ultimate Software Update Script - Gets software from the source, then packages it for deployment

-----

##What is this?

USUS (Ultimate Software Update Script) is a Windows Powershell Script (v2.0+) that will check for updated installers for just about any installer. If you give it a set of packages to run with, it'll make sure your Installers are on the latest version, and package them up in a convenient format. (Batch, Lansweeper, PDQ Deploy, Self-Extracting Installer)

-----

##Why Should I Use This Instead Of...?

USUS gives you more control over what you bring into your environment, while allowing you to make sure you always have the latest patches available.

 * You don't have to worry about what code could be hidden inside of a download script
   - The source code of USUS is freely available, and USUS Packages can be verified before placing into service. You can even create your own packages. (Verification for installers downloaded with the script coming soon)

 * You don't have to replace your current deployment method
   - USUS integrates with multiple deployment options (Good ole batch files, Lansweeper, PDQ Deploy), with support for automatic importation coming soon.

 * It doesn't cost you anything
   - Though submitting USUS packages to /r/USUScript is appreciated.


-----

##Running the Script

 - Create a Config.conf and place it inside of your ConfigDir (Start with the [Template](https://raw.githubusercontent.com/JL421/USUS/master/Config/Template.conf))

 - Run the script from command line, or create a scheduled task to keep your installers up to date automatically.

    Usage: USUS.ps1 -ConfigDir [Your ConfigDirectory Path] [-ForceDeploymentPackage]

    Required Flags :
     -ConfigDir    This is where all of the parts of the script live.
    This currently contains the PackageRepo, IncludesDir, and Base Config

    Optional Flags :
     -ForceDeploymentPackage This flag forces Deployment Packages to be rebuilt on every run.


As of now, the script is unsigned, this may change in the future, depending on if it's a big request.

As a result, there are two ways to run the script:

1. **Recommended** : `Powershell.exe -ExecutionPolicy Bypass -File [Path to Script] -ConfigDir [Path to Config Directory]`
 * This runs only the script in Bypass mode, bypassing the need for a signed script, but still preventing other unsigned scripts from running.
2. Globally setting Powershell's Execution Policy to Bypass.
 * **Highly Unrecommended**

-----

## Adding/Modifying Packages

Adding Packages is easy, either create one from the [Template](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/Template.conf), or grab one from the community. Then just place it into your Config\Packages Directory.

-----
##Pre-Built Packages

  * 7 zip - [32 Bit MSI](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/7Zip.conf) - [64 Bit MSI](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/7Zipx64.conf)
  * [Adobe Air](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/AdobeAir.conf)
  * [Adobe Reader](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/AdobeReader.conf)
  * [FileZilla](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/FileZilla.conf)
  * [Firefox](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/Firefox.conf)
  * [Firefox ESR](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/FirefoxESR.conf) - /u/Cyrandir
  * [Flash Player (Firefox)](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/FlashPlayer-Firefox.conf) - Must provide your own Distribution Link (http://www.adobe.com/products/players/flash-player-distribution.html)
  * [Flash Player (IE)](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/FlashPlayer-IE.conf) - Must provide your own Distribution Link (http://www.adobe.com/products/players/flash-player-distribution.html)
  * Google Chrome - [64 Bit MSI](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/GoogleChrome-x64MSI.conf)
  * Shockwave -  [MSI](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/Shockwave.conf) -  /u/Cyrandir
  * Skype - [MSI](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/Skype.conf) - /u/Cyrandir
  * VLC - [32 Bit](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/VLC.conf) - [64 Bit](https://raw.githubusercontent.com/JL421/USUS/master/Config/Packages/VLCx64.conf)
