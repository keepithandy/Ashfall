$ErrorActionPreference = 'Stop'
$assetIds = @('painted_wooden_cabinet','electric_stove','small_wooden_table_01','painted_wooden_chair_01','old_bed_frame','metal_office_desk','chemistry_set','industrial_microscope','retro_multimeter','cassette_player','service_pistol','bolt_action_rifle_7_62','dining_table')
$stageRoot = Join-Path $PSScriptRoot 'sources'
New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
$records = @()
foreach ($assetId in $assetIds) {
  $assetDir = Join-Path $stageRoot $assetId
  New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
  $manifest = Invoke-RestMethod -Uri "https://api.polyhaven.com/files/$assetId"
  $info = Invoke-RestMethod -Uri "https://api.polyhaven.com/info/$assetId"
  $manifest | ConvertTo-Json -Depth 30 | Set-Content (Join-Path $assetDir 'upstream-files.json')
  $info | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $assetDir 'upstream-info.json')
  $package = $manifest.blend.'1k'.blend
  if (-not $package.url) { throw "Missing Blender source: $assetId" }
  $files = @([pscustomobject]@{relative=([IO.Path]::GetFileName(([uri]$package.url).AbsolutePath)); data=$package})
  foreach ($entry in $package.include.PSObject.Properties) { $files += [pscustomobject]@{relative=$entry.Name;data=$entry.Value} }
  foreach ($entry in $files) {
    $dest = [IO.Path]::GetFullPath((Join-Path $assetDir $entry.relative))
    if (-not $dest.StartsWith($assetDir + [IO.Path]::DirectorySeparatorChar)) { throw 'Unsafe package path' }
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($dest)) -Force | Out-Null
    if (-not (Test-Path -LiteralPath $dest)) { Invoke-WebRequest -Uri $entry.data.url -OutFile $dest }
    $hash = (Get-FileHash -LiteralPath $dest -Algorithm MD5).Hash.ToLowerInvariant()
    if ($hash -ne $entry.data.md5) { throw "Checksum mismatch: $dest" }
    $records += [pscustomobject]@{asset=$assetId;path=$dest;url=$entry.data.url;md5=$hash;license='CC0';license_url='https://polyhaven.com/license'}
  }
  $records | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $stageRoot 'acquisition.json')
  Write-Output "Verified $assetId ($($files.Count) files)"
}
