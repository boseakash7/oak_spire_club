# Same as: flutter build apk --release
# Obfuscation is enabled automatically via android/gradle.properties

param(
    [switch]$SplitPerAbi
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$SymbolsDir = Join-Path $ProjectRoot "build\app\outputs\symbols"

Set-Location $ProjectRoot
New-Item -ItemType Directory -Force -Path $SymbolsDir | Out-Null

$buildArgs = @(
    "build", "apk",
    "--release",
    "--obfuscate",
    "--split-debug-info=$SymbolsDir"
)

if ($SplitPerAbi) {
    $buildArgs += "--split-per-abi"
}

Write-Host "Building obfuscated release APK..."
Write-Host "Debug symbols will be saved to: $SymbolsDir"
Write-Host "(Keep symbols private - needed to deobfuscate Crashlytics stack traces.)"

flutter @buildArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Build complete."
    Write-Host "APK output: build\app\outputs\flutter-apk\"
    Write-Host "Symbols:    $SymbolsDir"
}

exit $LASTEXITCODE
