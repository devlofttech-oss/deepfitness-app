param(
  [string]$SupabaseUrl = "https://iqhrhxxvhtokqltqkqoz.supabase.co",
  [string]$ServiceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ServiceRoleKey)) {
  throw "Set SUPABASE_SERVICE_ROLE_KEY or pass -ServiceRoleKey. Do not use the anon key for this migration."
}

$headers = @{
  "apikey" = $ServiceRoleKey
  "Authorization" = "Bearer $ServiceRoleKey"
  "Content-Type" = "application/json"
}

$oldExerciseNames = @(
  "Bench Press",
  "Bicep Curl",
  "Cable Fly",
  "Deadlift",
  "Incline Dumbbell Press",
  "Lat Pulldown",
  "Lateral Raises",
  "Leg Press",
  "Seated Row",
  "Shoulder Press",
  "Squat",
  "Tricep Pushdown"
)

$datasetSourceByOldName = @{
  "Bench Press" = "Barbell_Bench_Press_-_Medium_Grip"
  "Bicep Curl" = "Dumbbell_Bicep_Curl"
  "Cable Fly" = "Cable_Crossover"
  "Deadlift" = "Barbell_Deadlift"
  "Incline Dumbbell Press" = "Incline_Dumbbell_Press"
  "Lat Pulldown" = "Wide-Grip_Lat_Pulldown"
  "Lateral Raises" = "Side_Lateral_Raise"
  "Leg Press" = "Leg_Press"
  "Seated Row" = "Seated_Cable_Rows"
  "Shoulder Press" = "Dumbbell_Shoulder_Press"
  "Squat" = "Barbell_Squat"
  "Tricep Pushdown" = "Triceps_Pushdown"
}

function Invoke-SupabaseJson($Method, $Path, $Body = $null, $Prefer = $null) {
  $requestHeaders = $headers.Clone()
  if ($Prefer) {
    $requestHeaders["Prefer"] = $Prefer
  }

  $uri = "$SupabaseUrl/rest/v1/$Path"
  $parameters = @{
    Method = $Method
    Uri = $uri
    Headers = $requestHeaders
    TimeoutSec = 120
  }

  if ($null -ne $Body) {
    $json = $Body | ConvertTo-Json -Depth 12 -Compress
    $parameters.Body = [System.Text.Encoding]::UTF8.GetBytes($json)
  }

  $response = Invoke-RestMethod @parameters
  if ($response.Count -eq 1 -and $response[0] -is [array]) {
    return $response[0]
  }
  return $response
}

function Escape-PostgrestValue($Value) {
  return $Value.Replace('"', '\"')
}

$oldNameFilter = ($oldExerciseNames | ForEach-Object { '"' + (Escape-PostgrestValue $_) + '"' }) -join ","

$oldRows = @(
  Invoke-SupabaseJson Get "exercises?select=id,name,muscle_group,source_id,image_urls&order=name.asc&limit=2000" |
    Where-Object { $_.name -in $oldExerciseNames -and [string]::IsNullOrWhiteSpace($_.source_id) }
)
$datasetRows = @(
  Invoke-SupabaseJson Get "exercises?select=id,source_id,name,muscle_group,image_urls&order=name.asc&limit=2000" |
    Where-Object { $_.source_id -in $datasetSourceByOldName.Values }
)

if ($oldRows.Count -ne $oldExerciseNames.Count) {
  $found = @($oldRows | ForEach-Object name)
  $missing = @($oldExerciseNames | Where-Object { $_ -notin $found })
  throw "Expected $($oldExerciseNames.Count) old exercises but found $($oldRows.Count). Missing: $($missing -join ', ')"
}

$datasetBySource = @{}
foreach ($row in $datasetRows) {
  $datasetBySource[$row.source_id] = $row
}

$missingSources = @($datasetSourceByOldName.Values | Where-Object { -not $datasetBySource.ContainsKey($_) })
if ($missingSources.Count -gt 0) {
  throw "Missing dataset replacement rows: $($missingSources -join ', ')"
}

$migrationRows = foreach ($oldName in $oldExerciseNames) {
  $old = $oldRows | Where-Object { $_.name -eq $oldName } | Select-Object -First 1
  $new = $datasetBySource[$datasetSourceByOldName[$oldName]]
  $workoutRefs = @(Invoke-SupabaseJson Get "workout_exercises?select=id&exercise_id=eq.$($old.id)")
  $logRefs = @(Invoke-SupabaseJson Get "exercise_logs?select=id&exercise_id=eq.$($old.id)")

  [pscustomobject]@{
    old_name = $oldName
    old_id = $old.id
    new_name = $new.name
    new_id = $new.id
    new_source_id = $new.source_id
    image_count = @($new.image_urls).Count
    workout_refs = $workoutRefs.Count
    log_refs = $logRefs.Count
  }
}

Write-Host "Planned dataset exercise migration"
Write-Host "Mode: $(if ($DryRun) { 'dry run' } else { 'apply' })"
Write-Host ""
$migrationRows | Format-Table old_name,new_name,image_count,workout_refs,log_refs -AutoSize

if ($DryRun) {
  exit 0
}

foreach ($row in $migrationRows) {
  if ($row.workout_refs -gt 0) {
    Invoke-SupabaseJson Patch `
      "workout_exercises?exercise_id=eq.$($row.old_id)" `
      @{ exercise_id = $row.new_id } `
      "return=minimal" | Out-Null
  }

  if ($row.log_refs -gt 0) {
    Invoke-SupabaseJson Patch `
      "exercise_logs?exercise_id=eq.$($row.old_id)" `
      @{ exercise_id = $row.new_id } `
      "return=minimal" | Out-Null
  }
}

$oldIdFilter = ($migrationRows | ForEach-Object { $_.old_id }) -join ","
$remainingWorkoutRefs = @(Invoke-SupabaseJson Get "workout_exercises?select=id,exercise_id&exercise_id=in.($oldIdFilter)")
$remainingLogRefs = @(Invoke-SupabaseJson Get "exercise_logs?select=id,exercise_id&exercise_id=in.($oldIdFilter)")

if ($remainingWorkoutRefs.Count -gt 0 -or $remainingLogRefs.Count -gt 0) {
  throw "Refusing to delete old exercises. Remaining workout refs: $($remainingWorkoutRefs.Count). Remaining log refs: $($remainingLogRefs.Count)."
}

Invoke-SupabaseJson Delete "exercises?id=in.($oldIdFilter)" $null "return=minimal" | Out-Null

$remainingOldRows = @(Invoke-SupabaseJson Get "exercises?select=id,name&source_id=is.null&name=in.($oldNameFilter)")
$missingImageRows = @(Invoke-SupabaseJson Get "exercises?select=id,name,source_id,image_urls&or=(image_urls.eq.%7B%7D,image_urls.is.null)&order=name.asc")

Write-Host ""
Write-Host "Done."
Write-Host "Old manual exercise rows remaining: $($remainingOldRows.Count)"
Write-Host "Exercise rows without image_urls remaining: $($missingImageRows.Count)"

if ($remainingOldRows.Count -gt 0 -or $missingImageRows.Count -gt 0) {
  exit 1
}
