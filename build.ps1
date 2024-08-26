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
$readme = "./README.md"

Write-Host "Building $appName"

try {
  #Clean or Create output Directory
  if (Test-Path $dst) {
    $cleanDst = $dst + "/*"
    Remove-Item -Recurse -Force $cleanDst
  }
  else {
    New-Item -ItemType "directory" -Path $dst
  }

  # Copy Readme File
  if (Test-Path $readme -PathType Leaf) {
    Copy-Item "./README.md" -Destination $dst
  }
  
  # Copy From Source to Destination
  $buildSrc = $src + "/*"
  
  Copy-Item -Path $buildSrc -Destination $dst -Recurse -Force
}
catch {
  Write-Host $PSItem.Exception.Message -ForegroundColor RED
}
finally {
  $Error.Clear()
}

Get-ChildItem $dst -Recurse -include *.toc, *.lua | 
Select-Object -expand FullName |
ForEach-Object {
  (Get-Content $_) -replace '{{INTERFACE}}', $interface | Set-Content $_
  (Get-Content $_) -replace '{{VERSION}}', $version | Set-Content $_
  (Get-Content $_) -replace '{{TITLE}}', $title | Set-Content $_
  (Get-Content $_) -replace '{{NOTES}}', $notes | Set-Content $_
  (Get-Content $_) -replace '{{AUTHOR}}', $author | Set-Content $_
}

$installdir = $wowdir + "\_retail_\Interface\AddOns\" + $appName

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