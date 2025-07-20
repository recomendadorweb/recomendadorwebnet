@echo off
setlocal enabledelayedexpansion

if not exist output (
    mkdir output
)

set /a skipcount=0
set /a processcount=0

for %%I in (*.webp) do (
    if exist "%%I" (
        set "filename=%%~nI"
        set "fullname=%%~nxI"

        set "skip=no"

        REM Saltar si es exactamente *-480w.webp, *-768w.webp, *-1200w.webp
        if "!fullname:~-10!"=="-480w.webp" set "skip=yes"
        if "!fullname:~-10!"=="-768w.webp" set "skip=yes"
        if "!fullname:~-11!"=="-1200w.webp" set "skip=yes"

        if "!skip!"=="yes" (
            echo Saltando: %%I (ya es version redimensionada)
            set /a skipcount+=1
        )

        if "!skip!"=="no" (
            echo Procesando: %%I
            set /a processcount+=1

            if not exist "output\!filename!-480w.webp" magick "%%I" -resize 480 "output\!filename!-480w.webp"
            if not exist "output\!filename!-768w.webp" magick "%%I" -resize 768 "output\!filename!-768w.webp"
            if not exist "output\!filename!-1200w.webp" magick "%%I" -resize 1200 "output\!filename!-1200w.webp"
        )
    )
)

echo.
echo ✅ Proceso completado.
echo Procesadas: %processcount% imagenes.
echo Saltadas: %skipcount% imagenes ya redimensionadas.
pause
