set GameDir=F:\SteamLibrary\steamapps\common\Unnamed Space Idle
set SrcDir=.\Mod

set numFilex=0

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

set include_args=
setlocal enabledelayedexpansion
for /l %%i in (1,1,%numFile%) do (
    ..\gdre_tools --headless --compile="%SrcDir%\!File%%i!.gd" --bytecode=4.5.1 --output="%SrcDir%"
)

ren "%GameDir%\SpaceIdle.pck.bak" "SpaceIdle.bak.pck"
set include_args=
for /l %%i in (1,1,%numFilex%) do (
    set include_args=!include_args! --patch-file="%SrcDir%\!Filex%%i!"="!Filex%%i!"
)
for /l %%i in (1,1,%numFile%) do (
    set include_args=!include_args! --patch-file="%SrcDir%\!File%%i!.gdc"="!Path%%i!!File%%i!.gdc"
)
..\gdre_tools --headless --pck-patch="%GameDir%\SpaceIdle.bak.pck" %include_args% --output="%GameDir%\SpaceIdle.pck"
endlocal
ren "%GameDir%\SpaceIdle.bak.pck" "SpaceIdle.pck.bak"

