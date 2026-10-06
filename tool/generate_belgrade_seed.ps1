# Convert geocoded JSON into Dart seed source.
$ErrorActionPreference = 'Stop'
$inPath = Join-Path $PSScriptRoot 'belgrade_places_geocoded.json'
$outPath = Join-Path $PSScriptRoot '..\lib\features\map\data\belgrade_dog_places_seed.dart'
if (-not (Test-Path $inPath)) { throw "Missing $inPath" }

$items = [System.IO.File]::ReadAllText($inPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("import '../domain/map_city.dart';")
[void]$sb.AppendLine("import '../domain/models/poi_model.dart';")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("/// Belgrade + metro dog places geocoded from verified street addresses")
[void]$sb.AppendLine("/// via Photon/OSM. Entries without reliable coordinates are omitted.")
[void]$sb.AppendLine("abstract final class BelgradeDogPlacesSeed {")
[void]$sb.AppendLine("  static const String source = 'VauVau Belgrade Seed / OSM Photon';")
[void]$sb.AppendLine("  static final DateTime lastVerified = DateTime(2026, 10, 6);")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("  static List<PoiModel> get all => [")

function Escape-Dart([string]$s) {
  if ($null -eq $s) { return '' }
  $t = $s.Replace('\', '\\')
  $t = $t.Replace("'", "\'")
  return $t
}

function Category-Enum([string]$c) {
  switch ($c) {
    'park' { 'PoiCategory.park' }
    'petShop' { 'PoiCategory.petShop' }
    'groomer' { 'PoiCategory.groomer' }
    'vet' { 'PoiCategory.vet' }
    'cafe' { 'PoiCategory.cafe' }
    'restaurant' { 'PoiCategory.restaurant' }
    'dogTreats' { 'PoiCategory.dogTreats' }
    'lodging' { 'PoiCategory.lodging' }
    'training' { 'PoiCategory.training' }
    'dogHotel' { 'PoiCategory.dogHotel' }
    'selfWash' { 'PoiCategory.selfWash' }
    'shelter' { 'PoiCategory.shelter' }
    'water' { 'PoiCategory.water' }
    default { 'PoiCategory.other' }
  }
}

$seen = @{}
foreach ($item in @($items)) {
  $key = ("{0}|{1}" -f $item.name.ToLowerInvariant(), $item.address.ToLowerInvariant())
  if ($seen.ContainsKey($key)) { continue }
  $seen[$key] = $true

  $cat = Category-Enum $item.category
  $name = Escape-Dart $item.name
  $addr = Escape-Dart $item.address
  $muni = Escape-Dart $item.municipality
  $src = Escape-Dart $item.sourceUrl
  $web = $item.website
  $lat = [double]$item.latitude
  $lon = [double]$item.longitude
  $dog = [bool]$item.dogFriendly

  [void]$sb.AppendLine("        PoiModel(")
  [void]$sb.AppendLine("          id: '$(Escape-Dart $item.id)',")
  [void]$sb.AppendLine("          name: '$name',")
  [void]$sb.AppendLine("          category: $cat,")
  [void]$sb.AppendLine("          address: '$addr',")
  [void]$sb.AppendLine("          latitude: $lat,")
  [void]$sb.AppendLine("          longitude: $lon,")
  [void]$sb.AppendLine("          municipality: '$muni',")
  [void]$sb.AppendLine("          city: MapCity.belgrade,")
  [void]$sb.AppendLine("          cityId: 'beograd',")
  if ($dog) {
    [void]$sb.AppendLine("          petFriendly: true,")
  }
  if ($web) {
    [void]$sb.AppendLine("          website: '$(Escape-Dart ([string]$web))',")
  }
  if ($src) {
    [void]$sb.AppendLine("          sourceUrl: '$src',")
  }
  [void]$sb.AppendLine("          verificationStatus: PoiVerificationStatus.verified,")
  [void]$sb.AppendLine("          lastVerified: lastVerified,")
  [void]$sb.AppendLine("          source: source,")
  [void]$sb.AppendLine("        ),")
}

[void]$sb.AppendLine("      ];")
[void]$sb.AppendLine("}")

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path (Split-Path $outPath -Parent)).Path + '\belgrade_dog_places_seed.dart', $sb.ToString(), $utf8NoBom)
# Write using absolute path constructed above carefully
$absOut = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\lib\features\map\data')).Path 'belgrade_dog_places_seed.dart'
[System.IO.File]::WriteAllText($absOut, $sb.ToString(), $utf8NoBom)
Write-Host "Wrote $($seen.Count) places -> $absOut"
