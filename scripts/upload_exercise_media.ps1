# Pushes the built exercise media to a Cloudflare R2 bucket.
#
# R2 speaks the S3 API, so this is `aws s3 sync` pointed at an R2 endpoint
# rather than anything Cloudflare-specific. Two things about that pairing are
# not obvious:
#
#   * aws-cli v2.23 and later attach integrity checksums to every request by
#     default. R2 rejects some of those, and the failure surfaces as an opaque
#     signature error rather than anything mentioning checksums, so the two
#     environment variables below are set to keep the CLI on the older
#     behaviour.
#   * Content-Type has to be forced per file type. `sync` guesses, and a video
#     served as application/octet-stream will not stream — the player has to
#     download the whole file before the first frame, which is exactly the
#     problem this media pipeline exists to avoid.
#
# Credentials come from an R2 API token (Cloudflare dashboard -> R2 -> Manage
# API Tokens). Pass them in the environment, never on the command line, where
# they would land in shell history:
#
#   $env:AWS_ACCESS_KEY_ID     = "<access key id>"
#   $env:AWS_SECRET_ACCESS_KEY = "<secret access key>"
#   .\scripts\upload_exercise_media.ps1 -AccountId <id> -Bucket deepfitness-media

param(
  [Parameter(Mandatory = $true)][string]$AccountId,
  [Parameter(Mandatory = $true)][string]$Bucket,
  [string]$Source = "X:\Code\DeepFitness_Assets\build",
  [string]$Prefix = "exercises",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Source)) {
  throw "Build output not found: $Source  (run scripts/build_exercise_media.py first)"
}
if ([string]::IsNullOrWhiteSpace($env:AWS_ACCESS_KEY_ID) -or
    [string]::IsNullOrWhiteSpace($env:AWS_SECRET_ACCESS_KEY)) {
  throw "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to your R2 API token first."
}

$endpoint = "https://$AccountId.r2.cloudflarestorage.com"

# See the note above: these keep aws-cli off the request checksums R2 refuses.
$env:AWS_REQUEST_CHECKSUM_CALCULATION = "when_required"
$env:AWS_RESPONSE_CHECKSUM_VALIDATION = "when_required"
$env:AWS_DEFAULT_REGION = "auto"

# The media is content-addressed by a stable exercise id and never edited in
# place, so it can be cached for a year. A new clip gets a new id.
$cacheControl = "public, max-age=31536000, immutable"

$passes = @(
  @{ Dir = "video";  Pattern = "*.mp4";  Type = "video/mp4" },
  @{ Dir = "poster"; Pattern = "*.webp"; Type = "image/webp" }
)

foreach ($pass in $passes) {
  $local = Join-Path $Source $pass.Dir
  if (-not (Test-Path -LiteralPath $local)) {
    Write-Output "skipping $($pass.Dir): not built"
    continue
  }

  $awsArgs = @(
    "s3", "sync", $local, "s3://$Bucket/$Prefix/$($pass.Dir)/",
    "--endpoint-url", $endpoint,
    "--exclude", "*", "--include", $pass.Pattern,
    "--content-type", $pass.Type,
    "--cache-control", $cacheControl,
    "--no-progress"
  )
  if ($DryRun) { $awsArgs += "--dryrun" }

  Write-Output ""
  Write-Output "=== $($pass.Dir) -> s3://$Bucket/$Prefix/$($pass.Dir)/  ($($pass.Type))"
  & aws @awsArgs
  if ($LASTEXITCODE -ne 0) { throw "aws s3 sync failed for $($pass.Dir)" }
}

Write-Output ""
Write-Output "Done. Public URLs follow the bucket's custom domain, for example:"
Write-Output "  https://<your-r2-domain>/$Prefix/video/0001.mp4"
Write-Output "  https://<your-r2-domain>/$Prefix/poster/0001.webp"
Write-Output ""
Write-Output "The asset licence forbids distributing these as standalone downloadable"
Write-Output "files, so serve them through a custom domain with bucket listing off."
