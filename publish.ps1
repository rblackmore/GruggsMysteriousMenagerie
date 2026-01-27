$config = Get-Content config.json | ConvertFrom-Json

$interface = $config.INTERFACE
$version = $config.VERSION
$appName = $config.APP_NAME
$title = $config.APP_TITLE
$author = $config.AUTHOR
$notes = $config.NOTES
$src = $config.SRC_DIR
$build = $config.BUILD_DIR
$publish = $config.PUBLISH_DIR
$wowdir = $env:WOW_INSTALL_DIR
$readme = "./README.md"

Write-Host "Publishing $appName"


Function Clear-Directory{

  param([string]$directory)

  Write-Host "Clearing $directory"

  if (Test-Path $directory)
  {
    $cleardir = $directory + "/*"
    Remove-Item -Recurse -Force $cleardir
  }
  else{
    New-Item -ItemType "directory" -Path $directory
  }
};

Function Copy-BuildToPublish{
  param([string]$directory)

  Write-Host "Copying from $directory to $build"
  New-Item -ItemType "directory" -Path $directory

  Copy-Item -Path "$build/*" -Destination $directory -Recurse -Force
}

try {

  # Clear Publish directory
  Clear-Directory -directory $publish

  # Copy Build Directory to Publish/AppName Directory
  $outputDir = "$publish/$appName"
  Copy-BuildToPublish -directory $outputDir

  # Compress Published App to zip
  $compress = @{
    Path = $outputDir
    CompressionLevel = "Fastest"
    Destination = "$publish/$appname-$version.zip"
  }

  Compress-Archive @compress
}
catch {
  Write-Host $PSItem.Exception.Messagew -ForegroundColor RED
}
finally{
  $Error.Clear()
}