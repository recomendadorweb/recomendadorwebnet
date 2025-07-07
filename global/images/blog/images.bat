@echo off
setlocal enabledelayedexpansion

REM Crear carpeta de salida
mkdir output 2>nul

REM Recorrer todas las imágenes .webp
for %%I in (*.webp) do (
    set "filename=%%~nI"
    echo Procesando: %%I

    magick "%%I" -resize 480 "output\!filename!-480w.webp"
    magick "%%I" -resize 768 "output\!filename!-768w.webp"
    magick "%%I" -resize 1200 "output\!filename!-1200w.webp"
)

echo.
echo ✅ Proceso completado. Las imágenes redimensionadas están en la carpeta "output".
pause