@echo off
REM Create a post without quoting the title.
REM   new VS Code C++ preLaunchTask exit code -1
REM   new <subdir>/<title>   -> content/posts/<subdir>/<title>.md
setlocal

if "%~1"=="" (
  echo Usage: new ^<title^>
  echo   new VS Code C++ preLaunchTask exit code -1
  echo   new algo/two pointers
  echo Write the title as-is, without quotes.
  exit /b 1
)

REM Join every argument into one title and drop any quotes that were typed.
set "title=%*"
set title=%title:"=%

pushd "%~dp0"
hugo new content "posts/%title%.md"
set "rc=%errorlevel%"
popd

endlocal & exit /b %rc%
