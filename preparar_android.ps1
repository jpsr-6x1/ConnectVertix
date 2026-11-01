$ErrorActionPreference = 'Stop'
$manifest = 'android/app/src/main/AndroidManifest.xml'
flutter create --platforms=android .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not (Test-Path $manifest)) { throw "AndroidManifest.xml nao encontrado" }
$content = Get-Content $manifest -Raw -Encoding UTF8
if ($content -notmatch 'android.permission.INTERNET') {
  $replacement = '$1' + "`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
  $content = $content -replace '(<manifest\b[^>]*>)', $replacement
  Set-Content -Path $manifest -Value $content -Encoding UTF8
}
Write-Host 'Projeto Android preparado e permissao de internet verificada.'
