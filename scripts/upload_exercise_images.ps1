param(
  [string]$DatasetPath = "C:\STORAGE\Code\DeepFitness\free-exercise-db",
  [string]$SupabaseUrl = "https://iqhrhxxvhtokqltqkqoz.supabase.co",
  [string]$Bucket = "exercise-images",
  [string]$ServiceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY,
  [switch]$DryRun,
  [switch]$Upsert,
  [switch]$SkipExisting,
  [int]$Limit = 0
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $DatasetPath)) {
  throw "Dataset path not found: $DatasetPath"
}

$exerciseImagesPath = Join-Path $DatasetPath "exercises"
if (-not (Test-Path -LiteralPath $exerciseImagesPath)) {
  throw "Exercises image folder not found: $exerciseImagesPath"
}

if (-not $DryRun -and [string]::IsNullOrWhiteSpace($ServiceRoleKey)) {
  throw "Set SUPABASE_SERVICE_ROLE_KEY or pass -ServiceRoleKey. Do not use the anon key for bulk uploads."
}

$files = Get-ChildItem -LiteralPath $exerciseImagesPath -Recurse -File -Filter "*.jpg" |
  Sort-Object FullName

if ($Limit -gt 0) {
  $files = $files | Select-Object -First $Limit
}

$headers = @{
  "apikey" = $ServiceRoleKey
  "Authorization" = "Bearer $ServiceRoleKey"
  "Content-Type" = "image/jpeg"
}

if ($Upsert) {
  $headers["x-upsert"] = "true"
}

$uploaded = 0
$skipped = 0
$failed = 0
$total = @($files).Count

Write-Host "Dataset: $DatasetPath"
Write-Host "Bucket:  $Bucket"
Write-Host "Files:   $total"
if ($DryRun) {
  Write-Host "Mode:    dry run"
} elseif ($Upsert) {
  Write-Host "Mode:    upload with upsert"
} else {
  Write-Host "Mode:    upload without overwrite"
}
Write-Host ""

foreach ($file in $files) {
  $basePath = $exerciseImagesPath.TrimEnd("\", "/") + [System.IO.Path]::DirectorySeparatorChar
  $relative = $file.FullName.Substring($basePath.Length)
  $objectPath = $relative.Replace("\", "/")
  $encodedPath = ($objectPath -split "/" | ForEach-Object {
    [System.Uri]::EscapeDataString($_)
  }) -join "/"
  $uploadUrl = "$SupabaseUrl/storage/v1/object/$Bucket/$encodedPath"
  $publicUrl = "$SupabaseUrl/storage/v1/object/public/$Bucket/$encodedPath"

  if ($DryRun) {
    Write-Host "[dry-run] $objectPath"
    continue
  }

  if ($SkipExisting) {
    try {
      Invoke-WebRequest -Method Head -Uri $publicUrl -TimeoutSec 20 | Out-Null
      $skipped++
      Write-Host "[skip] $objectPath"
      continue
    } catch {
      # Object is probably missing; continue to upload.
    }
  }

  try {
    Invoke-WebRequest `
      -Method Post `
      -Uri $uploadUrl `
      -Headers $headers `
      -InFile $file.FullName `
      -TimeoutSec 60 | Out-Null
    $uploaded++
    Write-Host "[ok]   $objectPath"
  } catch {
    $failed++
    Write-Warning "[fail] $objectPath :: $($_.Exception.Message)"
  }
}

Write-Host ""
Write-Host "Done."
Write-Host "Uploaded: $uploaded"
Write-Host "Skipped:  $skipped"
Write-Host "Failed:   $failed"

if ($failed -gt 0) {
  exit 1
}
