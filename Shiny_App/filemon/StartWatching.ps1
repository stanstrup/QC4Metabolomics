### Function to read ini file
Function Parse-IniFile ($file) {
  $ini = @{}

 # Create a default section if none exist in the file. Like a java prop file.
 $section = "NO_SECTION"
 $ini[$section] = @{}

  switch -regex -file $file {
    "^\[(.+)\]$" {
      $section = $matches[1].Trim()
      $ini[$section] = @{}
    }
    "^\s*([^#].+?)\s*=\s*(.*)" {
      $name,$value = $matches[1..2]
      # skip comments that start with semicolon:
      if (!($name.StartsWith(";"))) {
        $ini[$section][$name] = $value.Trim()
      }
    }
  }
  $ini
}


### Read ini file
$ini = Parse-IniFile "../../MetabolomiQCs.conf"

      

# http://superuser.com/questions/226828/how-to-monitor-a-folder-and-trigger-a-command-line-action-when-a-file-is-created/844034#844034

### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = "Z:\9999_temp_test2" #$ini["folders"]["base"] 
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true  

### DEFINE ACTIONS AFTER A EVENT IS DETECTED
    $action = { $path = $Event.SourceEventArgs.FullPath
                $changeType = $Event.SourceEventArgs.ChangeType
                $logline = "$(Get-Date);$changeType;$path"
				#$logline = "$path"
				New-Item -ItemType Directory -Force -Path temp
                Add-content "temp/$(get-date -f yyyy-MM-dd-HH-mm-ss).log" -value $logline
              }    
### DECIDE WHICH EVENTS SHOULD BE WATCHED + SET CHECK FREQUENCY  
    $created = Register-ObjectEvent $watcher "Created" -Action $action
    #$changed = Register-ObjectEvent $watcher "Changed" -Action $action
    #$deleted = Register-ObjectEvent $watcher "Deleted" -Action $action
    $renamed = Register-ObjectEvent $watcher "Renamed" -Action $action
	$Error = Register-ObjectEvent $watcher "Error" -Action $action
    while ($true) {sleep 5}
	
	
