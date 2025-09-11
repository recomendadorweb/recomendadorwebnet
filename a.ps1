param(
  [switch]$DryRun,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

# === NUEVO: encoder UTF-8 sin BOM global ===
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Patrones para detectar autor y tipo
$reAutor = '\{\%\s*assign\s+autor\s*=\s*site\.data\.autor\.autores\.([A-Za-z0-9_-]+)\s*\%\}'
$reTipoD = '\{\%\s*assign\s+tipo\s*=\s*"([^"]+)"\s*\%\}'
$reTipoS = "\{\%\s*assign\s+tipo\s*=\s*'([^']+)'\s*\%\}"

function Get-FileTextAndEncoding([string]$Path) {
  $sr = New-Object System.IO.StreamReader($Path, $true) # detecta BOM
  $text = $sr.ReadToEnd()
  $encoding = $sr.CurrentEncoding
  $sr.Close()
  # === NUEVO: por si el U+FEFF quedó en el string, lo limpiamos ===
  $text = $text -replace '^\uFEFF',''
  return [pscustomobject]@{ Text = $text; Encoding = $encoding }
}

function Write-FileWithEncoding([string]$Path, [string]$Text, [System.Text.Encoding]$Encoding) {
  $sw = New-Object System.IO.StreamWriter($Path, $false, $Encoding)
  $sw.Write($Text)
  $sw.Close()
}

function Set-YamlKeyInline([string]$Yaml, [string]$Key, [string]$Value, [switch]$Force) {
  if ([string]::IsNullOrWhiteSpace($Value)) { return @{ yaml=$Yaml; changed=$false } }
  $pat = "(?m)^\s*"+[regex]::Escape($Key)+"\s*:.*$"
  if ($Yaml -match $pat) {
    if (-not $Force) { return @{ yaml=$Yaml; changed=$false } }
    $new = [regex]::Replace($Yaml, $pat, ('{0}: {1}' -f $Key,$Value))
    return @{ yaml=$new; changed=$true }
  } else {
    if ($Yaml -and -not $Yaml.EndsWith("`n")) { $Yaml += "`n" }
    return @{ yaml=($Yaml + ('{0}: {1}' -f $Key,$Value)); changed=$true }
  }
}

# Recorremos los .html
$files = Get-ChildItem -Path . -Filter *.html -Recurse -File |
         Where-Object { $_.FullName -notmatch '\\_site\\|\\node_modules\\|\\\.git\\' }

[int]$scanned=0; [int]$touched=0; [int]$changed=0

foreach ($f in $files) {
  $scanned++
  $file = Get-FileTextAndEncoding -Path $f.FullName
  $raw = $file.Text

  # Detectar saltos de línea
  $NL = "`n"
  if ($raw -match "`r`n") { $NL = "`r`n" }

  # ¿Tiene BOM de origen?
  $hadBom = ($file.Encoding.Preamble.Length -gt 0)

  if ($raw -notmatch $reAutor -and $raw -notmatch $reTipoD -and $raw -notmatch $reTipoS) {
    # === NUEVO: si no hay assigns pero sí BOM, solo regraba sin BOM ===
    if ($hadBom -and -not $DryRun) {
      Write-FileWithEncoding -Path $f.FullName -Text $raw -Encoding $Utf8NoBom
      Write-Host "[BOM] $($f.FullName) -> convertido a UTF-8 sin BOM"
      $changed++
    } else {
      Write-Host "[SKP] $($f.FullName)"
    }
    continue
  }
  $touched++

  # Extraer front matter si existe
  $hasFM = $false; $yaml = ""; $body = $raw
  $m = [regex]::Match($raw,'^(?s)---\r?\n(.*?)\r?\n---\r?\n(.*)$')
  if ($m.Success) {
    $hasFM = $true
    $yaml = $m.Groups[1].Value
    $body = $m.Groups[2].Value
  }

  # Detectar valores
  $autor = $null
  $ma = [regex]::Match($body,$reAutor); if ($ma.Success) { $autor = $ma.Groups[1].Value }
  $tipo = $null
  $mt = [regex]::Match($body,$reTipoD); if (-not $mt.Success) { $mt = [regex]::Match($body,$reTipoS) }
  if ($mt.Success) { $tipo = $mt.Groups[1].Value }

  if (-not $autor -and -not $tipo) { continue }

  $didChange = $false
  if ($hasFM) {
    $res = Set-YamlKeyInline $yaml 'autor' $autor -Force:$Force
    $yaml = $res.yaml; if ($res.changed) { $didChange = $true }

    $res = Set-YamlKeyInline $yaml 'tipo'  $tipo  -Force:$Force
    $yaml = $res.yaml; if ($res.changed) { $didChange = $true }

    if (-not $didChange -and -not $hadBom) { Write-Host "[SKP] $($f.FullName)"; continue }

    $out = '---' + $NL + $yaml + $NL + '---' + $NL + $body
  } else {
    # Crear nuevo front matter mínimo
    $lines = @()
    if ($autor) { $lines += ('autor: {0}' -f $autor) }
    if ($tipo)  { $lines += ('tipo: {0}'  -f $tipo)  }
    if ($lines.Count -eq 0) { continue }
    $out = '---' + $NL + ($lines -join $NL) + $NL + '---' + $NL + $raw
    $didChange = $true
  }

  if ($DryRun) {
    Write-Host "[DRY] $($f.FullName) -> autor=$autor tipo=$tipo (hadBOM=$hadBom)"
  } else {
    $bak = "$($f.FullName).bak"
    if (-not (Test-Path -LiteralPath $bak)) { Copy-Item $f.FullName $bak }
    # === CAMBIO CLAVE: siempre escribir en UTF-8 sin BOM ===
    Write-FileWithEncoding -Path $f.FullName -Text $out -Encoding $Utf8NoBom
    Write-Host "[ OK] $($f.FullName) -> autor=$autor tipo=$tipo (UTF-8 sin BOM)"
    $changed++
  }
}

Write-Host "`nRevisados: $scanned"
Write-Host "Con assigns: $touched"
Write-Host "Modificados: $changed"
