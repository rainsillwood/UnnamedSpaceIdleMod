set GameDir=F:\SteamLibrary\steamapps\common\Unnamed Space Idle
set DistDir=.\Origin

set File0=game_data.cdb
set File1=PurchaseHelper
set File2=RedeemCode
set File3=EventHelper
set File4=SynthModuleArea
set File5=ComputeArea

set Path1=purchase
set Path2=interface
set Path3=interface/events
set Path4=interface/synth
set Path5=interface/compute

ren "%GameDir%\SpaceIdle.pck.bak" "SpaceIdle.bak.pck" || ren "%GameDir%\SpaceIdle.pck" "SpaceIdle.bak.pck"

..\gdre_tools --headless --extract="%GameDir%\SpaceIdle.bak.pck" ^
--include="%File0%" ^
--include="%Path1%/%File1%.gdc" ^
--include="%Path2%/%File2%.gdc" ^
--include="%Path3%/%File3%.gdc" ^
--include="%Path4%/%File4%.gdc" ^
--include="%Path5%/%File5%.gdc" ^
--output="%DistDir%"

..\gdre_tools --headless --decompile="%DistDir%\%Path1%\%File1%.gdc" --bytecode=4.5.1  --output="%DistDir%"
..\gdre_tools --headless --decompile="%DistDir%\%Path2%\%File2%.gdc" --bytecode=4.5.1  --output="%DistDir%"
..\gdre_tools --headless --decompile="%DistDir%\%Path3%\%File3%.gdc" --bytecode=4.5.1  --output="%DistDir%"
..\gdre_tools --headless --decompile="%DistDir%\%Path4%\%File4%.gdc" --bytecode=4.5.1  --output="%DistDir%"
..\gdre_tools --headless --decompile="%DistDir%\%Path5%\%File5%.gdc" --bytecode=4.5.1  --output="%DistDir%"

pause