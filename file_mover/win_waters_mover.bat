@echo off

REM ****** SETTINGS ******
REM No trailing spaces!
set "infolder=C:\Users\tmh331\Desktop\temp with spaces\in"
set "outfolder=C:\Users\tmh331\Desktop\temp with spaces\out"
set "delim=_"
set "expect_delims=4"


REM SCRIPT STARTS HERE
setlocal enableDelayedExpansion
set /a "token_start=%expect_delims%+1"
set /a "token_end=%expect_delims%+2"
	
	
REM Resursively look for folders with _extern.inf files
for /d /r "%infolder%" %%i in (*) do  @if exist %%i\_extern.inf (

	echo ****** Processing file "%%~i" ******
	
	REM export variables
	for /f "delims=" %%B in ('set token_') do (
		if "!"=="" endlocal
		set "%%B"
    )
	
	
	for /F "tokens=1,%token_start%,%token_end% delims=%delim%" %%a in ("%%~ni") do (
		REM echo the raw folder is %%i
		if "%%b" == "" (echo Too few delimiters in "%%~xni") else (
			if not "%%c" == "" (echo Too many delimiters in "%%~xni") else (
			
			
				REM Create project folder if doesn't exist
				if not exist "%outfolder%\%%a.raw\Data" (
					echo creating folder "%outfolder%\%%a.raw\Data"
					mkdir "%outfolder%\%%a.raw\Data"
				)
				
				REM move raw folder if doesn't exist
				if exist "%outfolder%\%%a.raw\Data\%%~nxi" echo raw folder already exists!
				
				if not exist "%outfolder%\%%a.raw\Data\%%~nxi\" (
					echo Moving "%%~fi" to "%outfolder%\%%a.raw\Data\%%~nxi"
					move  "%%~fi" "%outfolder%\%%a.raw\Data\%%~nxi"
				)
			
				
				
				
			)	 
		)
	)
	
	

)
