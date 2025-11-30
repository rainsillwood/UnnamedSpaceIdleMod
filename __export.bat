set GameDir=F:\SteamLibrary\steamapps\common\Unnamed Space Idle
set DistDir=.\Origin

set Filex1=game_data.cdb

set numFilex=1

set File1=SaveLoad
set File2=RedeemCode
set File3=EventHelper
set File4=SynthModuleArea
set File5=ComputeArea
set File6=EnergyVoid
set File7=LimitedUpgradeButton
set File8=PurchaseHelper
set File9=DBImport
set File10=SynthPointsArea

set Path1=
set Path2=interface/
set Path3=interface/events/
set Path4=interface/synth/
set Path5=interface/compute/
set Path6=battle/
set Path7=upgrades/
set Path8=purchase/
set Path9=
set Path10=interface/synth/

set numFile=10

ren "%GameDir%\SpaceIdle.pck.bak" "SpaceIdle.bak.pck" || ren "%GameDir%\SpaceIdle.pck" "SpaceIdle.bak.pck"

set include_args=
setlocal enabledelayedexpansion
for /l %%i in (1,1,%numFilex%) do (
    set include_args=!include_args! --include="!Filex%%i!"
)
for /l %%i in (1,1,%numFile%) do (
    set include_args=!include_args! --include="!Path%%i!!File%%i!.gdc"
)
..\gdre_tools --headless --extract="%GameDir%\SpaceIdle.bak.pck" %include_args% --output="%DistDir%"

for /l %%i in (1,1,%numFile%) do (
    ..\gdre_tools --headless --decompile="%DistDir%\!Path%%i!!File%%i!.gdc" --bytecode=4.5.1 --output="%DistDir%"
)
endlocal

