@echo off
setlocal disableDelayedExpansion
>"%~1.new" (
  for /f "usebackq eol= tokens=*" %%A in ("%~1") do if "%%A" neq "" (
    set "ln=%%A"
    setlocal enableDelayedExpansion
    for %%k in (
      4096 2048 1024 512 256 128 64 32 16 8 4 2 1
    ) do for /f "eol= tokens=*" %%B in ("!ln:~-%%k!.") do (
      setlocal disableDelayedExpansion
      if "%%B" equ "." (
        endlocal
        set "ln=!ln:~0,-%%k!"
      ) else endlocal
    )
    echo !ln!
    endlocal
  )
)
move /y "%~1.new" "%~1" >nul