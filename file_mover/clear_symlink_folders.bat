@echo off

set "infolder=C:\Users\tmh331\Desktop\temp with spaces\in"


for /d /r "%infolder%" %%i in (*) do (

	fsutil reparsepoint query "%%i" | find "Symbolic Link" >nul && echo Deleting link: %%i && rm "%%i"

)



