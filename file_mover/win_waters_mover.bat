@echo off
REM No trailing spaces!
set "infolder=C:\Users\tmh331\Desktop\temp with spaces\in"
set "outfolder=C:\Users\tmh331\Desktop\temp with spaces\out"


REM Resursively look for folders with _extern.inf files
for /d /r "%infolder%" %%i in (*) do  @if exist %%i\_extern.inf (

	REM echo the raw folder is %%i

	REM tokens decide which part to take of the split string.
	REM "tokens=1,3" would take first and third and make %%b avaiable

	for /F "tokens=1 delims=_" %%a in ("%%~ni") do (
		
		REM Create project folder if doens't exist
		if not exist "%outfolder%\%%a.raw\Data\" (
		echo creating folder %outfolder%\%%a.raw\Data
		mkdir "%outfolder%\%%a.raw\Data"
		)
		
		REM move raw folder if doesn't exist
		if exist "%outfolder%\%%a.raw\Data\%%~nxi" echo raw folder already exists!
		
		if not exist "%outfolder%\%%a.raw\Data\%%~nxi" (
		echo Moving "%%~fi" to "%outfolder%\%%a.raw\Data\%%~nxi"
		move  "%%~fi" "%outfolder%\%%a.raw\Data\%%~nxi"
		)
	)

)
