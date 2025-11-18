<#
Encodes a keystore file to base64 for uploading to CI secrets (GitHub Actions).
Usage: .\scripts\encode_keystore.ps1 -keystorePath android/app/keystore.jks
#>
param(
    [string]$keystorePath = "android/app/keystore.jks"
)
if (!(Test-Path $keystorePath)) {
    Write-Error "Keystore not found at $keystorePath"
    exit 1
}

$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $keystorePath))
$base64 = [System.Convert]::ToBase64String($bytes)
Write-Output $base64

Write-Host "\nCopy the printed base64 string into the GitHub repository secret named 'KEYSTORE_BASE64'."