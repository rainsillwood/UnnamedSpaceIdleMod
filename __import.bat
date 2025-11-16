set GameDir=F:\SteamLibrary\steamapps\common\Unnamed Space Idle
set SrcDir=.\Mod

set File00=game_data.cdb

set File1=PurchaseHelper
set File2=RedeemCode
set File3=EventHelper
set File4=SynthModuleArea
set File5=ComputeArea
set File6=EnergyVoid
set File7=SaveLoad

set Path1=purchase/
set Path2=interface/
set Path3=interface/events/
set Path4=interface/synth/
set Path5=interface/compute/
set Path6=battle/
set Path7=

..\gdre_tools --headless --compile="%SrcDir%\%File1%.gd" --bytecode=4.5.1  --output="%SrcDir%"
..\gdre_tools --headless --compile="%SrcDir%\%File2%.gd" --bytecode=4.5.1  --output="%SrcDir%"
..\gdre_tools --headless --compile="%SrcDir%\%File3%.gd" --bytecode=4.5.1  --output="%SrcDir%"
..\gdre_tools --headless --compile="%SrcDir%\%File4%.gd" --bytecode=4.5.1  --output="%SrcDir%"
..\gdre_tools --headless --compile="%SrcDir%\%File5%.gd" --bytecode=4.5.1  --output="%SrcDir%"
..\gdre_tools --headless --compile="%SrcDir%\%File6%.gd" --bytecode=4.5.1  --output="%SrcDir%"
..\gdre_tools --headless --compile="%SrcDir%\%File7%.gd" --bytecode=4.5.1  --output="%SrcDir%"

ren "%GameDir%\SpaceIdle.pck.bak" "SpaceIdle.bak.pck"

..\gdre_tools --headless --pck-patch="%GameDir%\SpaceIdle.bak.pck" ^
--patch-file="%SrcDir%\%File00%"="%File00%" ^
--patch-file="%SrcDir%\%File1%.gdc"="%Path1%%File1%.gdc" ^
--patch-file="%SrcDir%\%File2%.gdc"="%Path2%%File2%.gdc" ^
--patch-file="%SrcDir%\%File3%.gdc"="%Path3%%File3%.gdc" ^
--patch-file="%SrcDir%\%File4%.gdc"="%Path4%%File4%.gdc" ^
--patch-file="%SrcDir%\%File5%.gdc"="%Path5%%File5%.gdc" ^
--patch-file="%SrcDir%\%File6%.gdc"="%Path6%%File6%.gdc" ^
--patch-file="%SrcDir%\%File7%.gdc"="%Path7%%File7%.gdc" ^
--output="%GameDir%\SpaceIdle.pck"

ren "%GameDir%\SpaceIdle.bak.pck" "SpaceIdle.pck.bak"

pause