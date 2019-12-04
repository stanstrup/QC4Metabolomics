@echo off

REM ****** SETTINGS ******
REM No trailing spaces!
set "infolder=C:\Users\tmh331\Desktop\gits\QC4Metabolomics_test\data\test-pro"
set "outfolder=C:\Users\tmh331\Desktop\gits\QC4Metabolomics_test\data\new_loc"
set "delim=_"
set "expect_delims=2"
set "symlinkback=TRUE"



REM SCRIPT STARTS HERE
setlocal enabledelayedexpansion
set /a "token_start=%expect_delims%+1"
set /a "token_end=%expect_delims%+2"
	
REM Resursively look for folders with _extern.inf files
for /d /r "%infolder%" %%i in (*) do  @if exist %%i\_extern.inf (

	echo ****** Start processing ******
	echo File: "%%i"
	
	REM detect if a symlink and if so don't do anything more.
	set "issymlink=FALSE"
	fsutil reparsepoint query "%%i" | find "Symbolic Link" >nul && echo Symlink detected. Skipping. && set "issymlink=TRUE"

	if not !issymlink! == TRUE (
	

		for /F "tokens=1,%token_start%,%token_end% delims=%delim%" %%a in ("%%~ni") do (
			REM echo the raw folder is %%i
			if "%%b" == "" (echo Filename check: Too few delimiters. File ignored.) else (
				if not "%%c" == "" (echo Filename check: Too many delimiters. File ignored.) else (
				
					echo Filename check: OK

					REM Create project folder if doesn't exist
					if not exist "%outfolder%\%%a\%%a.pro\Data" (
						echo creating folder "%outfolder%\%%a\%%a.pro\Data"
						mkdir "%outfolder%\%%a\%%a.pro\Data"
					)
					
					REM move raw folder if doesn't exist
					if exist "%outfolder%\%%a\%%a.pro\Data\%%~nxi" echo raw folder already exists! Folder ignored.
					
					if not exist "%outfolder%\%%a\%%a.pro\Data\%%~nxi\" (
						PING localhost -n 30 >NUL
						echo Moving "%%~fi" to "%outfolder%\%%a\%%a.pro\Data\%%~nxi"
						robocopy "%%~fi" "%outfolder%\%%a\%%a.pro\Data\%%~nxi" /E /MOVE
						
						REM make symlink in original location
						if %symlinkback% == TRUE (
							mklink /D "%%~fi" "%outfolder%\%%a\%%a.pro\Data\%%~nxi"
							
						REM write to text file the path of the new file
						echo "%%a\%%a.pro\Data\%%~nxi" >> %outfolder%\raw_filelist.txt
						)
					)

				)	 
			)
		)


	)

	echo ******* End processing *******
	echo.

)
