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
