$config = Get-Content config.json | ConvertFrom-Json

$interface = $config.INTERFACE
$version = $config.VERSION
$appName = $config.APP_NAME
$title = $config.APP_TITLE
$author = $config.AUTHOR
$notes = $config.NOTES
$src = $config.SRC_DIR
$dst = $config.BUILD_DIR
$wowdir = $env:WOW_INSTALL_DIR

$installdir = $wowdir + "\_retail_\Interface\AddOns\" + $appName

Write-Host "Installing $appName to $installdir"

Function Clear-Directory{

  param([string]$directory)

  if (Test-Path $directory)
  {
    $cleardir = $directory + "/*"
    Remove-Item -Recurse -Force $cleardir
  }
  else{
    New-Item -ItemType "directory" -Path $directory
  }
};

if (!(Test-Path $dst)) 
{
  Write-Host "Build the Project First"
  Exit 1
}

try {
  Clear-Directory -directory $installdir
  
  $buildSrc = $dst + "/*"
  Copy-Item -Path $buildSrc -Destination $installdir -Recurse -Force
  
}
catch {
  Write-Host $PSItem.Exception.Message -ForegroundColor RED
}
finally {
  $Error.Clear()
}