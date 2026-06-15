param(
  [string]$DatasetPath = "C:\STORAGE\Code\DeepFitness\free-exercise-db",
  [string]$SupabaseUrl = "https://iqhrhxxvhtokqltqkqoz.supabase.co",
  [string]$Bucket = "exercise-images",
  [string]$ServiceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY,
  [switch]$DryRun,
  [int]$StartOffset = 0,
  [int]$Limit = 0,
  [int]$BatchSize = 100
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $DatasetPath)) {
  throw "Dataset path not found: $DatasetPath"
}

$jsonPath = Join-Path $DatasetPath "dist\exercises.json"
if (-not (Test-Path -LiteralPath $jsonPath)) {
  throw "Dataset JSON not found: $jsonPath"
}

if (-not $DryRun -and [string]::IsNullOrWhiteSpace($ServiceRoleKey)) {
  throw "Set SUPABASE_SERVICE_ROLE_KEY or pass -ServiceRoleKey. Do not use the anon key for imports."
}

if ($BatchSize -lt 1) {
  throw "BatchSize must be 1 or greater."
}

$items = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($StartOffset -gt 0) {
  $items = $items | Select-Object -Skip $StartOffset
}
if ($Limit -gt 0) {
  $items = $items | Select-Object -First $Limit
}

function ConvertTo-StringArray($value) {
  if ($null -eq $value) {
    return @()
  }
  if ($value -is [string]) {
    return @($value)
  }
  return @($value | ForEach-Object {
    if ($null -ne $_) {
      $_.ToString()
    }
  })
}

function Get-PublicImageUrl($imagePath) {
  $encodedPath = ($imagePath -split "/" | ForEach-Object {
    [System.Uri]::EscapeDataString($_)
  }) -join "/"
  return "$SupabaseUrl/storage/v1/object/public/$Bucket/$encodedPath"
}

$rows = foreach ($item in $items) {
  $instructions = @(ConvertTo-StringArray $item.instructions)
  $primaryMuscles = @(ConvertTo-StringArray $item.primaryMuscles)
  $secondaryMuscles = @(ConvertTo-StringArray $item.secondaryMuscles)
  $imageUrls = @(ConvertTo-StringArray $item.images | ForEach-Object {
    Get-PublicImageUrl $_
  })

  [pscustomobject]@{
    source_id = $item.id
    name = $item.name
    description = ($instructions -join " ")
    muscle_group = if ($primaryMuscles.Count -gt 0) { $primaryMuscles[0] } else { "other" }
    rest_seconds = 60
    equipment = $item.equipment
    level = $item.level
    category = $item.category
    force = $item.force
    mechanic = $item.mechanic
    primary_muscles = $primaryMuscles
    secondary_muscles = $secondaryMuscles
    instructions = $instructions
    image_urls = @($imageUrls)
    source_name = "yuhonas/free-exercise-db"
    source_license = "Unlicense"
    imported_at = (Get-Date).ToUniversalTime().ToString("o")
  }
}

$total = @($rows).Count
Write-Host "Dataset: $DatasetPath"
Write-Host "Rows:    $total"
Write-Host "Offset:  $StartOffset"
Write-Host "Mode:    $(if ($DryRun) { 'dry run' } else { 'upsert metadata' })"
Write-Host ""

if ($DryRun) {
  $rows | Select-Object -First 3 | ConvertTo-Json -Depth 10
  exit 0
}

$headers = @{
  "apikey" = $ServiceRoleKey
  "Authorization" = "Bearer $ServiceRoleKey"
  "Content-Type" = "application/json"
  "Prefer" = "resolution=merge-duplicates"
}

$endpoint = "$SupabaseUrl/rest/v1/exercises?on_conflict=source_id"
$imported = 0
$failed = 0

for ($offset = 0; $offset -lt $total; $offset += $BatchSize) {
  $batch = @($rows | Select-Object -Skip $offset -First $BatchSize)
  $body = $batch | ConvertTo-Json -Depth 12 -Compress
  $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

  try {
    Invoke-RestMethod `
      -Method Post `
      -Uri $endpoint `
      -Headers $headers `
      -Body $bodyBytes `
      -TimeoutSec 120 | Out-Null
    $imported += $batch.Count
    Write-Host "[ok] $imported / $total"
  } catch {
    $failed += $batch.Count
    $errorBody = ""
    if ($_.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($_.ErrorDetails.Message)) {
      $errorBody = $_.ErrorDetails.Message
    }
    if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
      $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $streamBody = $reader.ReadToEnd()
      $reader.Dispose()
      if (-not [string]::IsNullOrWhiteSpace($streamBody)) {
        $errorBody = $streamBody
      }
    }
    if ([string]::IsNullOrWhiteSpace($errorBody)) {
      $errorBody = $_.Exception.Message
    }
    Write-Warning "[fail] batch starting at $($StartOffset + $offset) :: $errorBody"
  }
}

Write-Host ""
Write-Host "Done."
Write-Host "Imported: $imported"
Write-Host "Failed:   $failed"

if ($failed -gt 0) {
  exit 1
}
