# House-number geocoding via Nominatim structured search (1 req/s policy).
# Only results that OSM resolves to the exact house number are kept; street
# centroids are rejected so markers never land on a random point of a street.
#
# Example:
#   ./tool/geocode_places_nominatim.ps1 -RawPath tool/kragujevac_places_raw.json `
#     -OutPath tool/kragujevac_places_nominatim.json -City Kragujevac
param(
  [Parameter(Mandatory)] [string]$RawPath,
  [Parameter(Mandatory)] [string]$OutPath,
  [Parameter(Mandatory)] [string]$City
)
$ErrorActionPreference = 'Stop'
$ua = 'VauVauApp/1.0 (seed geocoder; contact: vauvau app)'
$jsonText = [System.IO.File]::ReadAllText((Resolve-Path $RawPath), [System.Text.Encoding]::UTF8)
$items = $jsonText | ConvertFrom-Json
$results = New-Object System.Collections.Generic.List[object]

foreach ($item in $items) {
  $street = (($item.query -split ',')[0]).Trim()
  if ($street -notmatch '\d') {
    continue
  }
  $uri = 'https://nominatim.openstreetmap.org/search?format=jsonv2&addressdetails=1&limit=3&countrycodes=rs' +
    '&street=' + [uri]::EscapeDataString($street) +
    '&city=' + [uri]::EscapeDataString($City)
  try {
    $resp = Invoke-RestMethod -Uri $uri -Headers @{ 'User-Agent' = $ua }
  } catch {
    Write-Host "ERR  $($item.id) :: $_"
    Start-Sleep -Seconds 2
    continue
  }
  Start-Sleep -Milliseconds 1200
  $hit = @($resp) | Where-Object { $_.address.house_number } | Select-Object -First 1
  if ($null -eq $hit) {
    Write-Host "MISS $($item.id) ($street)"
    continue
  }
  $obj = [ordered]@{
    id          = [string]$item.id
    latitude    = [math]::Round([double]$hit.lat, 6)
    longitude   = [math]::Round([double]$hit.lon, 6)
    houseNumber = [string]$hit.address.house_number
    road        = [string]$hit.address.road
    displayName = [string]$hit.display_name
  }
  $results.Add([pscustomobject]$obj) | Out-Null
  Write-Host ("OK   {0,-36} {1,10} {2,10} {3} {4}" -f $item.id, $obj.latitude, $obj.longitude, $obj.road, $obj.houseNumber)
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($OutPath, ($results | ConvertTo-Json -Depth 4), $utf8NoBom)
Write-Host "Done: $($results.Count) house-level hits -> $OutPath"
