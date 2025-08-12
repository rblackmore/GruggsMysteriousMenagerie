$config = Get-Content config.json | ConvertFrom-Json

$interface = $config.INTERFACE
$version = $config.VERSION
$appName = $config.APP_NAME
$title = $config.APP_TITLE
$author = $config.AUTHOR
$notes = $config.NOTES
$src = $config.SRC_DIR
$dst = $config.BUILD_DIR
$wowdir = $config.WOW_INSTALL_DIR

$installdir = $wowdir + "\_retail_\Interface\AddOns\" + $appName

Write-Host "Installing $appName to $installdir"

 if (!(Test-Path $dst)) 
 {
    Write-Host "Build the Project First"
    Exit 1
 }

try {
  # Clean or Create Install Directory
  if (Test-Path $installdir) {
    $clean = $installdir + "/*"
    Remove-Item -Recurse -Force $clean
  }
  else {
    New-Item -ItemType "directory" -Path $installdir
  }
  
  $buildSrc = $dst + "/*"
  Copy-Item -Path $buildSrc -Destination $installdir -Recurse -Force
  
}
catch {
  Write-Host $PSItem.Exception.Message -ForegroundColor RED
}
finally {
  $Error.Clear()
}