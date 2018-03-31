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

set rVersion "1.1-rc1"

proc fpoll {parm} {
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
          if {[regexp {Exec=/bin/chmenu ([^\n]*)} $data - fnum]} {
            scan $fnum "%d" b
            scan $folder "%d" a
            if {[expr $b < $a]} { continue }
          }
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
          if {$parm != ""} {
            set spath ${hakchipath}${folder}/${subfolder}
            if !{[catch { file copy $spath $parm } err]} {
              set infile [open "${parm}$subfolder/${subfolder}.desktop" r]
              fconfigure $infile -translation lf
              set data [read $infile]
              close $infile
              regexp "${subfolder}/(\[^\n\]*)" $data - fname2
              regsub -all {Exec=([^\n]*)} $data "Exec=/bin/md /var/games/${subfolder}/$fname2" data
              regsub -all {Path=([^\n]*)} $data "Path=/var/lib/clover/profiles/0/$subfolder" data
              regsub -all {Icon=([^\n]*)} $data "Icon=/var/games/${subfolder}/${subfolder}.png" data
              set outfile [open "${parm}/$subfolder/${subfolder}.desktop" w]
              fconfigure $outfile -translation lf
              puts $outfile [string trim $data]
              close $outfile
            }            
	# puts $err
	  }
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
  fconfigure $outfile -translation crlf
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
    set infile [open "$parm" r]
    fconfigure $infile -translation crlf
    set data [read $infile]
    close $infile
    set outfile [open "${parm}.bak" w]
    fconfigure $outfile -translation crlf
    puts $outfile $data
    close $outfile
    set ccodes [join $codes ";"]
    regsub -all {SelectedGamesSnes=[^\n]*} $data "SelectedGamesSnes=;$ccodes" data
    set outfile [open "$parm" w]
    fconfigure $outfile -translation crlf
    puts $outfile $data
    close $outfile
  }
}

proc main {parm1 parm2} {
  global outpath codes value
  puts "Initializing..."
  finit
  puts -nonewline "Parsing folders..."
  fpoll $parm2
  puts ""
  puts -nonewline "Processing..."
  flush stdout
  process "000" "  "
  puts ""
  if {$parm1 != ""} {
    puts "Rebuilding selected games..."
    rebuildselection $parm1
  }
  puts "Finishing..."
  ffinish
  puts "Done."
  puts ""
  puts "Please manually copy \"${outpath}folders_snes.xml\" to your hakchi \"config\" folder."
  puts "Please manually copy all png files in \"${outpath}icons/\" to your hakchi \"folder_images\" folder."
  if {[info exists value(/g)]} {
    puts "Please manually copy the folders in \"$parm2\" to your hakchi \"games_snes\" folder."
  }
}

set options [list "/C" "/G"]
set options_description [list \
"/C filename\t\tUpdates selected games in the supplied hakchi config filename" \
"/G directory\t\tPulls game directories and places them into the specified directory" \
]

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
  puts "Usage: rebuild <games-folder> <output-folder> \[/C hakchi-config-file\] \[/G output-directory\]"
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
      puts "Usage: rebuild <games-folder> <output-folder> \[/C hakchi-config-file\] \[/G output-directory\]"
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
  if {[info exists value(/g)] && ![file exists $value(/g)]} {
    puts "Error: Specified output games directory \"$value(/g)\" not found."
    exit
  }
  puts ""
  puts "Rebuild XML $rVersion by StrikeLight, 2018."
  puts ""
  set starttime [clock microseconds]
  if {[info exists value(/c)]} {
    set parm1 $value(/c)
  } else {
    set parm1 ""
  }
  if {[info exists value(/g)]} {
    set parm2 $value(/g)
    if {[string index $parm2 end] != "/"} {
      set parm2 "${parm2}/"
    }
  } else {
    set parm2 ""
  }
  main $parm1 $parm2
  set endtime [clock microseconds]
  puts ""
  puts "Execution time: [format %.03f [expr ($endtime - $starttime)/1000000.0]] seconds"
}
