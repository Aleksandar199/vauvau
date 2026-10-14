# Geocode a city's seed candidates via Photon (OSM), biased to the city center.
# Results outside the bounding box are dropped (never saved as 0,0 or as the
# city center). Each hit records whether it matched a house number or only a
# street/area, so the Dart seed can flag approximate coordinates.
#
# Example:
#   ./tool/geocode_places.ps1 -RawPath tool/kragujevac_places_raw.json `
#     -OutPath tool/kragujevac_places_geocoded.json `
#     -CenterLat 44.0128 -CenterLon 20.9114 `
#     -MinLat 43.95 -MaxLat 44.08 -MinLon 20.80 -MaxLon 21.00
param(
  [Parameter(Mandatory)] [string]$RawPath,
  [Parameter(Mandatory)] [string]$OutPath,
  [Parameter(Mandatory)] [double]$CenterLat,
  [Parameter(Mandatory)] [double]$CenterLon,
  [Parameter(Mandatory)] [double]$MinLat,
  [Parameter(Mandatory)] [double]$MaxLat,
  [Parameter(Mandatory)] [double]$MinLon,
  [Parameter(Mandatory)] [double]$MaxLon
)
$ErrorActionPreference = 'Stop'
$ua = 'VauVauApp/1.0 (seed geocoder)'
$jsonText = [System.IO.File]::ReadAllText((Resolve-Path $RawPath), [System.Text.Encoding]::UTF8)
$items = $jsonText | ConvertFrom-Json
$results = New-Object System.Collections.Generic.List[object]

function Test-InBox([double]$lat, [double]$lon) {
  return ($lat -ge $MinLat -and $lat -le $MaxLat -and $lon -ge $MinLon -and $lon -le $MaxLon)
}

function Invoke-Photon([string]$query) {
  $uri = "https://photon.komoot.io/api/?q=$([uri]::EscapeDataString($query))&lat=$CenterLat&lon=$CenterLon&limit=5&lang=en"
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
      $resp = Invoke-RestMethod -Uri $uri -Headers @{ 'User-Agent' = $ua }
      Start-Sleep -Milliseconds 700
      foreach ($feature in @($resp.features)) {
        $coords = $feature.geometry.coordinates
        $lon = [double]$coords[0]
        $lat = [double]$coords[1]
        if (-not (Test-InBox $lat $lon)) { continue }
        $p = $feature.properties
        return [pscustomobject]@{
          lat         = $lat
          lon         = $lon
          label       = [string]$p.name
          street      = [string]$p.street
          housenumber = [string]$p.housenumber
          osmType     = [string]$p.type
          osmKey      = "$($p.osm_key)=$($p.osm_value)"
        }
      }
      return $null
    } catch {
      Write-Host "retry $attempt :: $_"
      Start-Sleep -Seconds (2 * $attempt)
    }
  }
  return $null
}

foreach ($item in $items) {
  $hit = Invoke-Photon $item.query
  if ($null -eq $hit) {
    Write-Host "SKIP: $($item.id) ($($item.query))"
    continue
  }
  $precision = if ($hit.housenumber) { 'house' } elseif ($hit.osmType -eq 'street') { 'street' } else { 'feature' }
  $obj = [ordered]@{
    id           = [string]$item.id
    latitude     = [math]::Round($hit.lat, 6)
    longitude    = [math]::Round($hit.lon, 6)
    precision    = $precision
    geocodeQuery = [string]$item.query
    geocodeLabel = "$($hit.label) | $($hit.street) $($hit.housenumber) | $($hit.osmKey)"
  }
  $results.Add([pscustomobject]$obj) | Out-Null
  Write-Host ("OK {0,-36} {1,10} {2,10} {3,-8} {4}" -f $item.id, $obj.latitude, $obj.longitude, $precision, $obj.geocodeLabel)
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($OutPath, ($results | ConvertTo-Json -Depth 4), $utf8NoBom)
Write-Host "Done: $($results.Count) / $(@($items).Count) -> $OutPath"
