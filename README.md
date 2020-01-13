# LibVec  

some assembly routines to make stuff easier.  
code reuse.  
library.  
A collection of routines I've modified from other code for ease of  
understanding or BIOS routines made into macros for quick use to save a  
few cycles at the expense of ROM space. 

Thanks to Malban Vide, Chris Malcolm, Graham Toal, probably others 
for reused/borrowed code. 

newest version always here:  
git clone https://github.com/gauze/LibVec.git  
or  
git pull 
if you already have it installed locally 

file: LibVecProjectProperty.xml is a project file from VIDE 

doc/ contains Documentation files 

examples/ are code examples of how to use the libraries 

lib/ is where the library stuff lives.  
lib/drawing/ : line and list drawing  
lib/eeprom-ds2431/ : MAXIM DS2431 1-Wire EEPROM routines  
lib/general/ : misc stuff math, housekeeping, timing ...  
lib/sound/ :  audio  
lib/text-printing/ : printing text on the screen, duh.  

