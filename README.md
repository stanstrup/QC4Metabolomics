# QC4metabolomics
QC systems for metabolomics studies



## Installation

WIP. You won't get very far at the moment...

* Run QC system on another computer



### Folder moving

*Optional*

#### Purpose
To move files from an instrument computer to another location as soon as an analytical run is finished (e.g. a network drive). This way you don't need to run the whole QC system on the instrument computer.
**These scripts are written for Waters' raw folder and should not be used directly for anything else.**

What the scripts are meant to do:

* Monitor when a run is done.
* Will check if the filename (really a folder name) has the expected number of delimiters.
* If the filename is in the right format the file will be move to the given location.
  **This script was written for the metabolomics group at NEXS and there are therefore specific parsing of the filename to decide the destination folder.** 
  * The first string before the first delimiter is used as the project name and a project folder is create such that the file 
    `%infolder%\test-pro_pos_test-sample-metstd.raw` will be moved to 
    `%outfolder%\test-pro.raw\Data\test-pro_pos_test-sample-metstd.raw`
* *Optionally* symlinks can be made from the original location to the destination folder. This way you can still access the file as if it was still in the original place even if it is actually access in the destination location. So you can  open the file normally in the instrument software that expect the file to exist at the original location.
* *Optionally* the above mentioned symlinks can be cleared my running a script.







#### Usage
* Copy the content of `file_mover` to the instrument computer where the files are located.

* Edit the top part of `win_waters_mover.bat` to point to the right folders and the settings you want.

  * `infolder` and `outfolder` are the source and destination folders respectively.
  * Like the QC system the file move expect to be able to parse information from the file name. So `delim` sets the character that separates the information.
  * `expect_delims` stats how many delimiters to expect in a filename. This is used to only parse files with the expected filename convention.
  * If `symlinkback` is TRUE a symbolic link will be made in the original location pointing to the destination location.

* *If you use symlinks* you need to:

  * Right click on Start → Run and launch "secpol.msc".
  * Open "Security Settings" → "Local Policies" → "User Rights Assignment" and select "Create symbolic links".
  * Click "Add User or Group..." → enter the username the system normally uses → click "Check Names" → Click "OK" → Click "OK"
  * Reboot *or* log out and log in again (or run "gpupdate/force" on the command-line as administrator).

* Edit `monitor_folder.bat` to point to the same input folder as in `win_waters_mover.bat.`

* Run `enable_monitor_at_startup.bat`. This should make the folder monitor start at reboot. A console windows will be visible if this worked (after reboot).

* *If you used symlinks* you can always remove all symlinks by running `clear_symlink_folders.bat`. Edit to set the location first. This should be same location as `infolder` in `win_waters_mover.bat`.

  



