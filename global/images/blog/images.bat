@echo off
setlocal EnableExtensions

rem --- Comprobar que ImageMagick (magick) está disponible ---
where magick >nul 2>&1
if errorlevel 1 (
  echo [ERROR] No se encuentra 'magick' en el PATH. Instala ImageMagick o agrega 'magick.exe' al PATH.
  echo        Descarga: https://imagemagick.org
  pause
  exit /b 1
)

rem --- Crear script PowerShell temporal ---
set "PS1=%TEMP%\img_home_resize_%RANDOM%.ps1"
> "%PS1%" echo $ErrorActionPreference='Stop'
>> "%PS1%" echo $converted=0; $homeCreated=0; $homeSkipped=0; $homeSourceSkipped=0
>> "%PS1%" echo $files = Get-ChildItem -File -Path .
>> "%PS1%" echo foreach($fi in $files^){
>> "%PS1%" echo ^  $name = $fi.BaseName
>> "%PS1%" echo ^  $ext  = ($fi.Extension).TrimStart('.').ToLower()
>> "%PS1%" echo ^  if($name -like '*-home'^){ $homeSourceSkipped++; continue }
>> "%PS1%" echo ^  $baseWebp = "$name.webp"
>> "%PS1%" echo ^  if($ext -ne 'webp'^){
>> "%PS1%" echo ^    if(-not (Test-Path $baseWebp)^){
>> "%PS1%" echo ^      ^& magick $fi.FullName $baseWebp
>> "%PS1%" echo ^      if($LASTEXITCODE -eq 0^){ $converted++ }
>> "%PS1%" echo ^    }
>> "%PS1%" echo ^  } else {
>> "%PS1%" echo ^    $baseWebp = $fi.Name
>> "%PS1%" echo ^  }
>> "%PS1%" echo ^  $homeFile = "$name-home.webp"
>> "%PS1%" echo ^  if(Test-Path $homeFile^){ $homeSkipped++; continue }
>> "%PS1%" echo ^  ^& magick $baseWebp -resize '120x120^>' $homeFile
>> "%PS1%" echo ^  if($LASTEXITCODE -eq 0^){ $homeCreated++ }
>> "%PS1%" echo }
>> "%PS1%" echo ""
>> "%PS1%" echo '✅ Proceso completado.'
>> "%PS1%" echo "Convertidas a .webp: $converted"
>> "%PS1%" echo "-home creadas: $homeCreated"
>> "%PS1%" echo "-home ya existentes (saltadas): $homeSkipped"
>> "%PS1%" echo "Fuentes -home detectadas y omitidas: $homeSourceSkipped"
>> "%PS1%" echo Read-Host 'Pulsa Enter para salir'

rem --- Ejecutar PowerShell (sin necesidad de cambiar la política de ejecución del sistema) ---
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"

rem --- Limpiar script temporal ---
del "%PS1%" >nul 2>&1

endlocal
