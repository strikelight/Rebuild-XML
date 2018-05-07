Rebuild XML is released under the GNU Public License.

Rebuild XML v1.2 by StrikeLight

Description:
============
This tool will attempt to re-create a lost folders_snes.xml file
based on the provided games path, as best it can.

Pre-requisites:
===============
Note: This has only been tested with SNESC Mini and Hakchi2 CE.
You must be using USB Host mode.
The hakchi "games" folder must still exist on the USB drive.
The program must NOT be run from the hakchi games folder.

Usage:
======
From command prompt, type:
rebuild <path/to/hakchi/games/snes-*> <path/to/output/folder> [/C hakchi-config-filename] [/G output-directory]

Example: rebuild G:/hakchi/games/snes-eur/ C:/temp/
Example 2: rebuild G:/hakchi/games/snes-eur/ C:/temp/ /C G:/tool/hakchi/config/config.ini
Example 3: rebuild G:/hakchi/games/snes-eur/ C:/temp/ /C G:/tool/hakchi/config/config.ini /G C:/temp/games/

The program will save folders_snes.xml to your output folder,
as well as creating an "icons" folder to the output folder with the folder icons.

If the /C option is used, the program will also attempt to re-add the games as being
selected in the supplied hakchi2 config.ini file.

If the /G option is used, the program will also attempt to copy the games folders to
the specified existing directory.  Useful for non-linked export setups to recover the games
folders to place into the hakchi2 games_snes folder.

Manually copy the resulting folders_snes.xml file to your Hakchi2 "config" folder,
and manually copy the images in the "icons" folder to your Hakchi2 "folder_images" folder.


Tips:
=====
- If you have an existing folders_snes.xml file that is functioning, please back it up.
- If your games path or output path have a space in them, please encapsulate the path in quotes.
- eg. "C:/temp/Path with spaces/"

Thanks:
=======
madmonkey,Cluster,bslenul,KMFDManic,Team Shinkansen,The Other Guys,Hakchi Resources,/r/miniSNESmods,the Hakchi community