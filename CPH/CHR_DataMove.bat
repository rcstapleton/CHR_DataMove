@REM ==========================================================================
@REM CHR_DataMove.bat
@REM 
@REM move a CHR file for a given year from the ETSU CPH CHR Plot Application download directory
@REM   to the application's plot data source directory
@REM
@REM Command Line Parameters:
@REM    %1 - year of file to move               (default: current year)
@REM    %2 - source directory for file to move  (default: given below)
@REM    %3 - target directory for file to move  (default: .)
@REM Outputs:
@REM   None
@REM Final Status:
@REM   0 for success; small positive integers for failure modes
@REM Effects:
@REM   Moves file from download directory to target directory
@REM   Outputs messages characterizing status of move
@REM
@REM Recommended: run with DOS extensions enabled - CMD /V:ON
@REM
@REM Author:  Phil Pfeiffer, April, 2023
@REM ==========================================================================

@REM  setlocal - export none of the variables that this .bat file sets to the .bat file's execution environment
@REM  setlocal EnableDelayedExpanson - enable use of !...! to re-enable variable expansion at need
@REM  set errorlevel= a must for retrieving command status; if errorlevel defined, cmd won't overwrite errorlevel

@setlocal
@setlocal EnableDelayedExpansion
@set errorlevel=

@REM ################################################################
@REM configure and validate operating environment
@REM ################################################################

@REM =================================================================================================
@REM default parameters:
@REM -. plot_data_file_prefix:      part of plot data file name that precedes the year to access
@REM -. plot_data_file_suffix:      part of plot data file name that follows the year to access
@REM -. plot_data_target_prefix:    part of plot data target file name that precedes the year to access
@REM -. plot_data_target_suffix:    part of plot data target file name that follows the year to access
@REM -. default_plot_data_year:     year for which to fetch plot data 
@REM -. default_download_directory: directory from which to acquire downloaded CHR data
@REM -. default_target_directory:   directory to which to transfer this data
@REM =================================================================================================

@REM Dosshell hack to parse date command for year, removing final ' '
@for /f "usebackq tokens=4 delims=/ " %%i in (`Date /T`) do @set current_year=%%i

@set default_plot_data_year=%current_year%

@set plot_data_file_prefix=
@set plot_data_file_suffix=.csv
@set default_download_directory=C:\Users\Administrator\Documents\Websites\CHR-DataGrab\wwwroot\uploads

@set plot_data_target_prefix=%plot_data_file_prefix%
@set plot_data_target_suffix=%plot_data_target_suffix%
@set default_target_directory=C:\Users\Administrator\Documents\Websites\CHR-Plot\wwwroot\uploads


@REM #####################################
@REM program proper
@REM #####################################

@REM ==================================================================================
@REM validate parameters; assign aliases for parameters
@REM -.  plot_data_year -      year for the data to transfer
@REM -.  download_directory -  name of directory containing file to transfer
@REM -.  target_directory -    name of directory that the plot program sources
@REM ==================================================================================

@set parameterCheckSucceeded=true

@set param=%1
@if defined %param (
  @set plot_data_year=%1
  @if "%param%"=="" (
    @echo %~n0: ?? malformed first [plot_data_year] parameter [%param%]: must be a nonempty string
    @set parameterCheckSucceeded=false
    @goto EndParameterChecks
  )
) else (
  @set plot_data_year=%default_plot_data_year%
)

@set param=%2
@if defined %param (
  @set download_directory=%2
  @if "%param%"=="" (
    @echo %~n0: ?? malformed second [download_directory] parameter [%param%]: must be a nonempty string
    @set parameterCheckSucceeded=false
    @goto EndParameterChecks
  )
) else @(
  @set download_directory=%default_download_directory%
)

@set param=%3
@if defined %param (
  @set target_directory=%3
  @if "%param%"=="" (
    @echo %~n0: ?? malformed third [target_directory] parameter [%param%]: must be a nonempty string
    @set parameterCheckSucceeded=false
    @goto EndParameterChecks
  )
) else @(
  @set target_directory=%default_target_directory%
)

@REM --------------------------------------------------------
@REM parameter check complete: quit if anything awry
@REM --------------------------------------------------------

:EndParameterChecks
@if %parameterCheckSucceeded%==false (
  @echo ?? %~n0: parameters check failed; exiting
  @goto fatalError1
)

@REM =======================================================
@REM validate operating environment
@REM =======================================================

@set environmentCheckSucceeded=true

@REM -----------------------------------------------------------------------------------------------
@REM check for supporting directories and files
@REM -----------------------------------------------------------------------------------------------

@if NOT exist "%download_directory%" (
  @echo ?? %~n0: can't find directory that contains downloaded CHR file ["%download_directory%"]
  @set environmentCheckSucceeded=false
) else @(
  @dir /A:D "%download_directory%" 1>nul 2>nul
  @if !errorlevel! neq 0 (
    @echo ?? %~n0: ["%download_directory%"] must be a directory
    @set environmentCheckSucceeded=false
  )
)

@if NOT exist "%target_directory%" (
  @echo ?? %~n0: can't find directory to which to move CHR file ["%target_directory%"]
  @set environmentCheckSucceeded=false
) else @(
  @dir /A:D "%target_directory%" 1>nul 2>nul
  @if !errorlevel! neq 0 (
    echo ?? %~n0: ["%target_directory%"] must be a directory
    @set environmentCheckSucceeded=false
  )
)

@if %environmentCheckSucceeded% equ false (
    @goto EndEnvironmentChecks
)

@set plot_data_file_name=%plot_data_file_prefix%%plot_data_year%%plot_data_file_suffix%
@set plot_data_file=%download_directory%\%plot_data_file_name%

@if NOT exist "%plot_data_file%" (
  @echo ?? %~n0: can't find specified CHR file ["%plot_data_file%"] for specified year ["%plot_data_year%"]
  @set environmentCheckSucceeded=false
  @goto EndEnvironmentChecks
)

@set plot_data_target_name=%plot_data_target_prefix%%plot_data_year%%plot_data_target_suffix%
@set plot_data_target=%target_directory%\%plot_data_file_name%

@if exist "%plot_data_target%" (
  @set /P permit_overwrite="File ["%plot_data_target%"] for specified year ["%plot_data_year%"] exists; enter 'Y' or 'y' to overwrite it: "
  if /I "!permit_overwrite!" neq "y" @(
     @echo exiting
     @goto normalExit
  )
)

@REM -------------------------------------------------------
@REM environment check complete: quit if anything awry
@REM -------------------------------------------------------

:EndEnvironmentChecks
@if %environmentCheckSucceeded% equ false (
  @echo ?? %~n0: environment check failed; exiting
  @goto fatalError2
)

@REM =======================================================
@REM do the move, then check result
@REM =======================================================

@copy /Y "%plot_data_file%" "%plot_data_target%" 1>nul
@if %errorlevel% neq 0 goto fatalError3

@if exist "%plot_data_target%" (
   @echo "%plot_data_target%" updated
) else @(
   @echo ?? %~n0: "%plot_data_target%" not updated - exiting
   @goto fatalError3
)

@del /F "%plot_data_file%" 1>nul
@if %errorlevel% neq 0 goto fatalError4

@if not exist "%plot_data_file%" (
   @echo "%plot_data_file%" removed
) else @(
   @echo ?? %~n0: "%plot_data_target%" not removed - exiting
   @goto fatalError4
)

@echo exiting

@REM =============================================
@REM script exit points
@REM =============================================


:fatalError1
@echo on
@endlocal
@set errorlevel=1
@goto :EOF

:fatalError2
@echo on
@endlocal
@set errorlevel=2
@goto :EOF

:fatalError3
@echo on
@endlocal
@set errorlevel=3
@goto :EOF

:fatalError4
@echo on
@endlocal
@set errorlevel=4
@goto :EOF

:normalExit
@echo on
@endlocal
@set errorlevel=0
@goto :EOF
