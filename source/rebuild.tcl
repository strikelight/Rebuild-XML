#!/bin/tclsh

# rebuild.tcl
#
#  Description: Attempts to rebuild an XML file for use with Hakchi2 CE
#
#
#  This file is part of Rebuild XML.
#
#  Rebuild XML is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  Rebuild XML is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Rebuild XML.  If not, see <http://www.gnu.org/licenses/>.

set rVersion "0.92-beta"

proc fpoll {} {
  global foldername foldericon gamename gameslist hakchipath outpath children codes
  set codes [list]
  foreach folder [glob -directory $hakchipath *] {
    if {[file isdirectory $folder]} {
      set folder [lindex [split $folder /] end]
      puts -nonewline "."
      flush stdout
      foreach subfolder [glob -directory $hakchipath $folder/*] {
        set subfolder [lindex [split $subfolder /] end]
        if {[string match "*CLV-S-00*" $subfolder]} {
          set data [read [set infile [open "${hakchipath}${folder}/${subfolder}/${subfolder}.desktop" r]]]
          close $infile
          regexp {Name=([^\n]*)} $data - fname
          if {$fname == "Back"} { continue }
          regexp {CLV-S-00(.*)} $subfolder - ele
          set parent($ele) $folder
          lappend children($folder) $ele
          set foldername($ele) $fname
          set foldericon($ele) $subfolder
          catch { file copy ${hakchipath}${folder}/${subfolder}/${subfolder}.png ${outpath}/icons }
        } elseif {[regexp {CLV-[^S]-*} $subfolder]} {
          set data [read [set infile [open "${hakchipath}${folder}/${subfolder}/${subfolder}.desktop" r]]]
          close $infile
          regexp {Name=([^\n]*)} $data - fname
          regsub -all "&" $fname "&amp;" fname
          set gamename($subfolder) $fname
          lappend gameslist($folder) $subfolder
          lappend codes $subfolder
        }
      }
    }
  }
}

proc finit {} {
  global outfile outpath
  if {![file exists ${outpath}/icons]} {
    file mkdir ${outpath}/icons
  }
  set outfile [open "${outpath}folders_snes.xml" w]
  puts $outfile "<?xml version=\"1.0\" encoding=\"utf-16\"?>"
  puts $outfile "<Tree>"
}

proc ffinish {} {
  global outfile
  puts $outfile "</Tree>"
  close $outfile
}

proc process {folder indent} {
  global gameslist children gamename foldername foldericon outfile
  puts -nonewline "."
  flush stdout
  if {[info exists gameslist($folder)]} {
    foreach game $gameslist($folder) {
      puts $outfile "${indent}<Game code=\"$game\" name=\"$gamename($game)\" />"
    }
  }
  if {[info exists children($folder)]} {
    foreach child $children($folder) {
      puts $outfile "${indent}<Folder name=\"$foldername($child)\" icon=\"$foldericon($child)\" position=\"3\">"  
      process $child "$indent  "
    }
  }
  if {$folder != "000"} {
    set indent [string range $indent 2 end]
    puts $outfile "${indent}</Folder>"
  }    
}

proc rebuildselection {parm} {
  global codes
  if {$parm != ""} {
    set data [read [set infile [open "$parm" r]]]
    close $infile
    set outfile [open "${parm}.bak" w]
    puts $outfile $data
    close $outfile
    set ccodes [join $codes ";"]
    regsub -all {SelectedGamesSnes=[^\n]*} $data "SelectedGamesSnes=;$ccodes" data
    set outfile [open "$parm" w]
    puts $outfile $data
    close $outfile
  }
}

proc main {parm} {
  global outpath codes
  puts "Initializing..."
  finit
  puts -nonewline "Parsing folders..."
  fpoll
  puts ""
  puts -nonewline "Processing..."
  flush stdout
  process "000" "  "
  puts ""
  if {$parm != ""} {
    puts "Rebuilding selected games..."
    rebuildselection $parm
  }
  puts "Finishing..."
  ffinish
  puts "Done."
  puts ""
  puts "Please manually copy \"${outpath}folders_snes.xml\" to your hakchi \"config\" folder."
  puts "Please manually copy all png files in \"${outpath}icons/\" to your hakchi \"folder_images\" folder."  
}

set options [list "/C"]
set options_description [list "/C filename\t\tUpdates selected games in the supplied hakchi config filename"]

proc isOpt {option} {
  global options
  foreach op $options {
    if {[string tolower $option] == [string tolower $op]} {
      return 1
    }
  }
  return 0
}

if {$argc < 2} {
  puts "Usage: rebuild <games-folder> <output-folder> \[/C hakchi-config-file\]"
  puts "Example: rebuild G:/hakchi/games/snes-eur/ C:/temp/"
  puts ""
  puts "Options:"
  puts ""
  for {set i 0} {$i < [llength $options]} {incr i} {
    puts "  [lindex $options_description $i]"
  }
} else {
  for {set j 2} {$j < [expr $argc]} {incr j} {
    if {[isOpt [lindex $argv $j]]} {
      set value([string tolower [lindex $argv $j]]) [lindex $argv [expr $j+1]]
      incr j
    } else {
      puts "Usage: rebuild <games-folder> <output-folder> \[/C hakchi-config-file\]"
      puts "Example: rebuild G:/hakchi/games/snes-eur/ C:/temp/"
      puts ""
      puts "Options:"
      puts ""
      for {set i 0} {$i < [llength $options]} {incr i} {
        puts "  [lindex $options_description $i]"
      }
      exit
    }	
  }
  set hakchipath [lindex $argv 0]
  set outpath [lindex $argv 1]
  if {[string index $hakchipath end] != "/"} {
    set hakchipath "${hakchipath}/"
  }
  if {[string index $outpath end] != "/"} {
    set outpath "${outpath}/"
  }
  if {![file exists $hakchipath]} {
    puts "Error: Games folder \"$hakchipath\" not found."
    exit
  }
  if {![file exists $outpath]} {
    puts "Error: Output path \"$outpath\" not found."
    exit
  }
  if {[string tolower $hakchipath] == [string tolower $outpath]} {
    puts "Error: games-folder path can not be the same as output-folder path."
    exit
  }
  if {[info exists value(/c)] && ![file exists $value(/c)]} {
    puts "Error: hakchi config file \"$value(/c)\" not found."
    exit
  }
  puts ""
  puts "Rebuild XML $rVersion by StrikeLight, 2018."
  puts ""
  set starttime [clock microseconds]
  if {[info exists value(/c)]} {
    set parm $value(/c)
  } else {
    set parm ""
  }
  main $parm
  set endtime [clock microseconds]
  puts ""
  puts "Execution time: [format %.03f [expr ($endtime - $starttime)/1000000.0]] seconds"
}
