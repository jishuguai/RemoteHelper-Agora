::=============================================================================
:: This script is the main entrance for building and releasing
:: Agora C# SDK to NuGet.
::
:: For pushing the SDK to NuGet, please set the API key for NuGet
:: as an environment variable called %NUGET_APIKEY%.
::
::  Input: %1 (TYPE) : build or publish
::         %2 (VERSION) : 3.4.0, etc.
::         %3 (CONFIG) : Debug or Release (For "%TYPE%"=="build" only)
::         %4 (APP-KEY) : The app-key for download iris
::         %5 (WIN-URL) : The url for iris_win
::         %6 (NUGET_API_KEY) : nuget api key for publish
::  eg:
::     .\build.bat build 3.2.1.7 Debug ABjRbSFow***jku4mjkBqJ6F6Ne8***WzGM1vXYZZ7EqDLtFcaPgL***u8ehmGjxX7syPabcL
::     .\build.bat publish 3.2.1.7 Release ABjRbSFow***jku4mjkBqJ6F6Ne8***WzGM1vXYZZ7EqDLtFcaPgL***u8ehmGjxX7syPabcL
:: Created by Yiqing Huang on Apr 23, 2021.
:: Modified by Yiqing Huang on May 12, 2021.
:: Modified by Hugo Chaan on September 2, 2021.
::=============================================================================
@echo off

SET CURDIR=%cd%
SET APP_KEY=%4
SET WIN_URL=%5
SET NUGET_API_KEY=%6

goto main

:main
setlocal
echo type[%1] version[%2] config[%3] app_key[%APP_KEY%] win_url[%WIN_URL%] nuget_api_key[%NUGET_API_KEY%]

SET TYPE=%1
if "%TYPE%"=="publish" (
    if "%NUGET_API_KEY%"=="" (
        echo Nuget Api Key cannot be empyty when publish!!!
        goto error
    )
)

if "%TYPE%"=="publish" (CALL :publish_to_nuget %2) else (CALL :build %2 %3)
endlocal
EXIT /B 0

:download_in_txt
setlocal
SET URL=%~1
SET OUT_FILENAME=%~2
SET HEADER="X-JFrog-Art-Api: %APP_KEY%"
curl -H %HEADER% %URL% -o %OUT_FILENAME%
endlocal
EXIT /B 0

:download_in_command
setlocal
SET URL=%~1
SET OUT_FILENAME=%~2
SET HEADER="X-JFrog-Art-Api: %APP_KEY%"
curl -H %HEADER% %URL% -o %OUT_FILENAME%
endlocal
EXIT /B 0

:: Download Iris and related native SDK libraries
:: according to the URL in 'url_config.txt'.
::
:: Params: %~1 (URL_FILE): The path to the url_config file.
::         %~2 (OUT_FILENAME): The output file name.
:download_library
setlocal
SET URL_FILE=%~1
SET OUT_FILENAME=%~2
for /F "usebackq delims=" %%a in (%URL_FILE%) do SET URL=%%a
echo =====Start downloading libraries=====
echo %URL_FILE%
echo %OUT_FILENAME%
echo URL: %URL%
if "%WIN_URL%"=="" (CALL :download_in_txt %URL% %OUT_FILENAME%) else (CALL :download_in_command %WIN_URL% %OUT_FILENAME%)
echo =====Finish downloading libraries=====
endlocal
EXIT /B 0


:: Build and push package to NuGet.
::
:: Params: %~1 (VERSION): 3.4.0, etc.
::
:: Notes: Please set the API key for NuGet upload as an environment
::        variable called %NUGET_APIKEY% in advance.
:publish_to_nuget
setlocal
SET SOURCE=https://api.nuget.org/v3/index.json
SET NUPKG_FILE_NAME=agora_rtc_sdk.%~1%.nupkg

call :build %~1 Release publish

SET PUBLISH_PATH=%CURDIR%\publish
cd %PUBLISH_PATH%
nuget setapikey %NUGET_API_KEY%
nuget.exe pack agora_rtc_sdk.nuspec

echo =====Start pushing package to NuGet=====
nuget.exe push %NUPKG_FILE_NAME% -Timeout 600 -Source %SOURCE%
if %errorlevel% == 0 (
    echo =====Publis Sucess, start removing unnecessary files=====
    rmdir /q /s %PUBLISH_PATH%
    echo =====Finish removing unnecessary files=====
) else (
    echo =====Publish package to NuGet failed !!!=====
	goto error
)
rmdir /q /s %CURDIR%\..\APIExample
echo =====Finish pushing package to NuGet=====

endlocal
EXIT /B 0

:: pack files for zip
:: Params: %~1 (CONFIG): Debug or Release    
:pre_packing
setlocal
SET CONFIG=%~1

echo "pre_packing"
::mkdir %CURDIR%\Agora_C#_SDK
::mkdir %CURDIR%\Agora_C#_SDK\x86 %CURDIR%\Agora_C#_SDK\x86_64 %CURDIR%\Agora_C#_SDK\agorartc %CURDIR%\Agora_C#_SDK\agorartc\agorartc
::xcopy /s /y %CURDIR%\iris\x86\* %CURDIR%\Agora_C#_SDK\x86\
::xcopy /s /y %CURDIR%\iris\x86_64\* %CURDIR%\Agora_C#_SDK\x86_64\
::xcopy /s /y %CURDIR%\agorartc\obj\x86\%CONFIG%\netcoreapp20\agorartc.dll %CURDIR%\Agora_C#_SDK\x86
::xcopy /s /y %CURDIR%\agorartc\obj\x64\%CONFIG%\netcoreapp20\agorartc.dll %CURDIR%\Agora_C#_SDK\x86_64

mkdir %CURDIR%\Agora_C#_SDK %CURDIR%\Agora_C#_SDK\libs %CURDIR%\Agora_C#_SDK\APIExample
mkdir %CURDIR%\Agora_C#_SDK\libs\netCore %CURDIR%\Agora_C#_SDK\libs\netFramework
mkdir %CURDIR%\Agora_C#_SDK\libs\netCore\x86 %CURDIR%\Agora_C#_SDK\libs\netCore\x86_64 %CURDIR%\Agora_C#_SDK\libs\netFramework\x86  %CURDIR%\Agora_C#_SDK\libs\netFramework\x86_64
xcopy /s /y %CURDIR%\iris\x86\* %CURDIR%\Agora_C#_SDK\libs\netCore\x86\
xcopy /s /y %CURDIR%\iris\x86_64\* %CURDIR%\Agora_C#_SDK\libs\netCore\x86_64\
xcopy /s /y %CURDIR%\iris\x86\* %CURDIR%\Agora_C#_SDK\libs\netFramework\x86\
xcopy /s /y %CURDIR%\iris\x86_64\* %CURDIR%\Agora_C#_SDK\libs\netFramework\x86_64\
xcopy /s /y %CURDIR%\agorartc\obj\x86\%CONFIG%\net40\agorartc.dll %CURDIR%\Agora_C#_SDK\libs\netFramework\x86
xcopy /s /y %CURDIR%\agorartc\obj\x64\%CONFIG%\net40\agorartc.dll %CURDIR%\Agora_C#_SDK\libs\netFramework\x86_64
xcopy /s /y %CURDIR%\agorartc\obj\x86\%CONFIG%\netcoreapp20\agorartc.dll %CURDIR%\Agora_C#_SDK\libs\netCore\x86
xcopy /s /y %CURDIR%\agorartc\obj\x64\%CONFIG%\netcoreapp20\agorartc.dll %CURDIR%\Agora_C#_SDK\libs\netCore\x86_64


endlocal
EXIT /B 0

:: pack files for publish
:: Params: %~1 (CONFIG): Debug or Release  
:pre_publish_to_nuget
echo "pre_publish_to_nuget"
setlocal
SET CONFIG=%~1
SET CONFIG_PATH=%CURDIR%\config
SET CONFIG_PATH_DST=%CURDIR%\publish
SET CONFIG_BIN_PATH_DST=%CURDIR%\publish\bin

mkdir %CONFIG_BIN_PATH_DST%\x86\netcoreapp20 %CONFIG_BIN_PATH_DST%\x86\net40 %CONFIG_BIN_PATH_DST%\x86_64\netcoreapp20 %CONFIG_BIN_PATH_DST%\x86_64\net40
xcopy /s /y %CONFIG_PATH%\agora_rtc_sdk.nuspec %CONFIG_PATH_DST%
xcopy /s /y %CONFIG_PATH%\agorartc_core20.props %CONFIG_BIN_PATH_DST%
xcopy /s /y %CONFIG_PATH%\agorartc_core20.targets %CONFIG_BIN_PATH_DST%
xcopy /s /y %CONFIG_PATH%\agorartc_framework40.props %CONFIG_BIN_PATH_DST%
xcopy /s /y %CONFIG_PATH%\agorartc_framework40.targets %CONFIG_BIN_PATH_DST%
xcopy /s /y %CURDIR%\iris\x86\*  %CONFIG_BIN_PATH_DST%\x86\
xcopy /s /y %CURDIR%\iris\x86_64\*  %CONFIG_BIN_PATH_DST%\x86_64\
xcopy /s /y %CURDIR%\agorartc\obj\x86\%CONFIG%\netcoreapp20\agorartc.dll %CONFIG_BIN_PATH_DST%\x86\netcoreapp20
xcopy /s /y %CURDIR%\agorartc\obj\x64\%CONFIG%\netcoreapp20\agorartc.dll %CONFIG_BIN_PATH_DST%\x86_64\netcoreapp20
xcopy /s /y %CURDIR%\agorartc\obj\x86\%CONFIG%\net40\agorartc.dll %CONFIG_BIN_PATH_DST%\x86\net40
xcopy /s /y %CURDIR%\agorartc\obj\x64\%CONFIG%\net40\agorartc.dll %CONFIG_BIN_PATH_DST%\x86_64\net40
endlocal
EXIT /B 0

:: clean
:post_packing
setlocal

echo =====Start removing unnecessary files=====
rmdir /q /s %CURDIR%\Agora_C#_SDK
rmdir /q /s %CURDIR%\iris %CURDIR%\agorartc
del /s %CURDIR%\agorartc.sln
echo =====Finish removing unnecessary files=====

endlocal
EXIT /B 0

:: Build and compress dlls into a zip file.
::
:: Params: %~1 (VERSION): 3.4.0, etc.
::         %~2 (CONFIG): Debug or Release
::         %~3 (PUBLISH): just for publish.
::
:: Notes: Please set the API key for NuGet upload as an environment
::        variable called %NUGET_APIKEY% in advance.
:build
setlocal
if "%~1"=="" goto error
if "%~2"=="" goto error
SET VERSION=%~1
SET CONFIG=%~2

echo =====Start building for %VERSION%=====

echo =====Start preparing for build=====
SET URL_FILE=url_config_csharp.txt
SET OUT_FILENAME=iris.zip
SET IRIS_PATH_x86=%CURDIR%/temp/iris_*/Win32
SET NATIVE_SDK_x86=%CURDIR%/temp/iris_*/RTC/Agora_Native_SDK_for_Windows_FULL/libs/x86
SET IRIS_PATH_x64=%CURDIR%/temp/iris_*/x64
SET NATIVE_SDK_x64=%CURDIR%/temp/iris_*/RTC/Agora_Native_SDK_for_Windows_FULL/libs/x86_64

CALL :download_library %URL_FILE% %OUT_FILENAME%
echo %CURDIR%\%OUT_FILENAME%
if not exist %CURDIR%\%OUT_FILENAME% (
    echo %CURDIR%\%OUT_FILENAME% not exist
    goto error
)
for /f %%i in ('dir /b %CURDIR%\%OUT_FILENAME%') do   set  file_size=%%~zi
if %file_size% leq 1048576 (
    echo file size %file_size% unnormal
	del /s %CURDIR%\%OUT_FILENAME%
    goto error
)
mkdir %CURDIR%\temp %CURDIR%\iris %CURDIR%\iris\x86 %CURDIR%\iris\x86_64
7z x %CURDIR%\%OUT_FILENAME% -o%CURDIR%\temp -aoa

powershell -command "cp -r %IRIS_PATH_x86%/Release/* %CURDIR%/iris/x86"
powershell -command "cp -r %NATIVE_SDK_x86%/*.dll %CURDIR%/iris/x86"
powershell -command "cp -r %NATIVE_SDK_x86%/*.lib %CURDIR%/iris/x86"
powershell -command "cp -r %IRIS_PATH_x64%/Release/* %CURDIR%/iris/x86_64"
powershell -command "cp -r %NATIVE_SDK_x64%/*.dll %CURDIR%/iris/x86_64"
powershell -command "cp -r %NATIVE_SDK_x64%/*.lib %CURDIR%/iris/x86_64"
mkdir %CURDIR%\agorartc
xcopy /s /y %CURDIR%\..\agorartc\* %CURDIR%\agorartc\
powershell -command "cp -r %CURDIR%/../*.sln %CURDIR%"

rmdir /q /s %CURDIR%\temp
del /s %CURDIR%\%OUT_FILENAME%
echo =====Finish preparing for build=====

echo =====Start building for x86=====
SET IRIS_PATH_x86=%CURDIR%\iris\x86
call %CURDIR%\compile-windows.bat x86 %CURDIR%\agorartc.sln %CONFIG% 2019
echo =====Finish building for x86=====

echo =====Start building for x64=====
SET IRIS_PATH_x64=%CURDIR%\iris\x86_64
call %CURDIR%\compile-windows.bat x64 %CURDIR%\agorartc.sln %CONFIG% 2019
echo =====Finish building for x64=====

echo =====Start packing=====
if "%~3" == "publish" (
    call :pre_publish_to_nuget %CONFIG%
)
call :pre_packing %CONFIG%
:: if "%~3"=="" rmdir /q /s %CURDIR%\agorartc\bin
rmdir /q /s %CURDIR%\agorartc\obj

::xcopy /s %CURDIR%\agorartc\* %CURDIR%\Agora_C#_SDK\agorartc\agorartc\
::powershell -command "cp -r %CURDIR%/agorartc.sln %CURDIR%/Agora_C#_SDK/agorartc"
xcopy /s %CURDIR%\..\..\APIExample\* %CURDIR%\Agora_C#_SDK\APIExample
::powershell -command "cp -r %CURDIR%/../../APIExample/APIExample.sln %CURDIR%/Agora_C#_SDK/APIExample
if exist %CURDIR%\Agora_C#_SDK\APIExample\binx64 (
    rmdir /q /s %CURDIR%\Agora_C#_SDK\APIExample\binx64
)
if exist  %CURDIR%\Agora_C#_SDK\APIExample\binx86 (
    rmdir /q /s %CURDIR%\Agora_C#_SDK\APIExample\binx86
)

mkdir %CURDIR%\output
cd /d Agora_C#_SDK
7z a -r %CURDIR%\output\Agora_C#_SDK_%VERSION%_%CONFIG%.zip  .\*
cd ..
echo =====Finish packing=====
call :post_packing
echo =====Finish building for %VERSION%=====
endlocal
EXIT /B 0

:: Error message.
:error
echo ERROR: Missing input parameter or sdk file unnormal!
EXIT /B 1
