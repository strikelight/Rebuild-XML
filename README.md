Rebuild XML is released under the GNU Public License.

Rebuild XML v0.9-beta by StrikeLight

Description:
============
This tool will attempt to re-create a lost folders_snes.xml file
based on the provided games path, as best it can.

Pre-requisites:
===============
Note: This has only been tested with SNESC Mini and Hakchi2 1.1.0 CE.
You must be using USB Host mode.
The hakchi games folder must still exist.
The program must NOT be run from the hakchi games folder.

Usage:
======
From command prompt, type:
rebuild <path/to/hakchi/games/snes-*> <path/to/output/folder>

Example: rebuild G:/hakchi/games/snes-eur/ C:/temp/

The program will save folders_snes.xml to your output folder,
as well as creating an "icons" folder to the output folder with the folder icons.

Manually copy the folders_snes.xml file to your Hakchi2 "config" folder,
and manually copy the images in the "icons" folder to your Hakchi2 "folder_images" folder.


Tips:
=====
- If you have an existing folders_snes.xml file that is functioning, please back it up.
- If your games path or output path have a space in them, please encapsulate the path in quotes.
- eg. "C:/temp/Path with spaces/"

Thanks:
=======
madmonkey,Cluster,KMFDManic,Team Shinkansen,/r/miniSNESmods,the Hakchi community