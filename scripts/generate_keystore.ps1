<#
PowerShell script to generate a keystore for signing the Android app.
Requires `keytool` (JDK) to be installed and available on PATH.
#>
param(
    [string]$alias = "code_sprout_key",
    [string]$keystorePath = "android/app/keystore.jks",
    [string]$storepass = "12345678",
    [string]$keypass = "12345678",
    [string]$dname = "CN=Your Name, OU=Dev, O=Organization, L=City, S=State, C=US"
)

$keystoreDir = Split-Path $keystorePath
if (!(Test-Path $keystoreDir)) { New-Item -ItemType Directory -Path $keystoreDir -Force | Out-Null }

$keytool = "keytool"
$cmd = "$keytool -genkeypair -v -keystore `"$keystorePath`" -storepass $storepass -keypass $keypass -alias $alias -keyalg RSA -keysize 2048 -validity 10000 -dname `"$dname`""

Write-Host "Running: $cmd"
Invoke-Expression $cmd

if (Test-Path $keystorePath) {
    Write-Host "Keystore generated at: $keystorePath"
} else {
    Write-Error "Keystore generation failed. Ensure keytool (from JDK) is installed and available on PATH."
}
