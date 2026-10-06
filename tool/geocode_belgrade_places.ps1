# Geocode Belgrade addresses via Photon (OSM). Bias to Belgrade. Retry on errors.
$ErrorActionPreference = 'Stop'
$rawPath = Join-Path $PSScriptRoot 'belgrade_places_raw.json'
$outPath = Join-Path $PSScriptRoot 'belgrade_places_geocoded.json'
$jsonText = [System.IO.File]::ReadAllText($rawPath, [System.Text.Encoding]::UTF8)
$items = $jsonText | ConvertFrom-Json
$results = New-Object System.Collections.Generic.List[object]
$ua = 'VauVauApp/1.0 (belgrade seed geocoder)'

function Test-InBelgradeBBox([double]$lat, [double]$lon) {
  return ($lat -ge 44.55 -and $lat -le 45.05 -and $lon -ge 19.95 -and $lon -le 20.75)
}

function Invoke-Photon([string]$query) {
  $uri = "https://photon.komoot.io/api/?q=$([uri]::EscapeDataString($query))&lat=44.8125&lon=20.4612&limit=3&lang=en"
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
      $resp = Invoke-RestMethod -Uri $uri -Headers @{ 'User-Agent' = $ua }
      Start-Sleep -Milliseconds 700
      if ($null -eq $resp -or $null -eq $resp.features -or @($resp.features).Count -eq 0) {
        return $null
      }
      foreach ($feature in @($resp.features)) {
        $coords = $feature.geometry.coordinates
        $lon = [double]$coords[0]
        $lat = [double]$coords[1]
        if (Test-InBelgradeBBox $lat $lon) {
          return [pscustomobject]@{
            lat   = $lat
            lon   = $lon
            label = [string]$feature.properties.name
            city  = [string]$feature.properties.city
          }
        }
      }
      # Accept first result if none in bbox but still Serbia-ish
      $first = @($resp.features)[0]
      $coords = $first.geometry.coordinates
      $lon = [double]$coords[0]
      $lat = [double]$coords[1]
      if (Test-InBelgradeBBox $lat $lon) {
        return [pscustomobject]@{
          lat   = $lat
          lon   = $lon
          label = [string]$first.properties.name
          city  = [string]$first.properties.city
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
  $street = (($item.address -split ',')[0]).Trim()
  $queries = @(
    "$($item.address), Belgrade, Serbia",
    "$street, $($item.municipality), Belgrade, Serbia",
    "$street, Belgrade, Serbia",
    "$($item.name), Belgrade, Serbia"
  )

  $hit = $null
  $used = $null
  foreach ($q in $queries) {
    $candidate = Invoke-Photon $q
    if ($null -ne $candidate) {
      $hit = $candidate
      $used = $q
      break
    }
  }

  if ($null -eq $hit) {
    Write-Host "SKIP: $($item.id)"
    continue
  }

  $obj = [ordered]@{
    id           = [string]$item.id
    name         = [string]$item.name
    category     = [string]$item.category
    address      = [string]$item.address
    municipality = [string]$item.municipality
    latitude     = [double]$hit.lat
    longitude    = [double]$hit.lon
    phone        = $(if ($item.PSObject.Properties.Name -contains 'phone') { [string]$item.phone } else { '' })
    website      = $(if ($item.PSObject.Properties.Name -contains 'website') { $item.website } else { $null })
    sourceUrl    = $(if ($item.PSObject.Properties.Name -contains 'sourceUrl') { [string]$item.sourceUrl } else { '' })
    dogFriendly  = $(if ($item.PSObject.Properties.Name -contains 'dogFriendly') { [bool]$item.dogFriendly } else { $false })
    geocodeQuery = $used
    geocodeLabel = [string]$hit.label
  }
  $results.Add([pscustomobject]$obj) | Out-Null
  Write-Host ("OK ({0}/{1}): {2} -> {3}, {4}" -f $results.Count, $items.Count, $item.id, $hit.lat, $hit.lon)
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($outPath, ($results | ConvertTo-Json -Depth 6), $utf8NoBom)
Write-Host "Done: $($results.Count) / $($items.Count) -> $outPath"
