# Runs the app in a browser, reliably.
#
#   powershell -File scripts\run_web.ps1
#   powershell -File scripts\run_web.ps1 -Port 5300 -Open
#
# Why a script rather than just `flutter run -d web-server`:
#
# Stopping a Flutter web server does not always free its port. The process
# that holds it is named "dartvm", not "dart", so the obvious kill misses it.
# A later `flutter run` then binds a different port while the browser keeps
# talking to the old server, which serves the build from before your edit.
# That looks exactly like a broken fix. This kills whatever actually holds
# the port first, by pid, and waits for it to let go.
#
# Android is not an option on a machine whose JVM cannot open a selector
# (Gradle dies with "Unable to establish loopback connection"). Web is the
# way to see the app there.

[CmdletBinding()]
param(
  [int]$Port = 5200,
  [switch]$Open,
  [switch]$Release
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Free-Port([int]$p) {
  $held = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
  if (-not $held) { return }
  foreach ($c in $held) {
    $proc = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
    if ($proc) {
      Write-Host "stopping $($proc.ProcessName) (pid $($proc.Id)) on port $p"
      Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
  }
  # Give the socket a moment to actually close before rebinding.
  for ($i = 0; $i -lt 20; $i++) {
    if (-not (Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue)) { return }
    Start-Sleep -Milliseconds 250
  }
  throw "Port $p is still held. Check for a stray dartvm process."
}

if (-not (Test-Path 'web\index.html')) {
  Write-Host 'no web target yet, creating one'
  flutter create --platforms=web . | Out-Null
}

Free-Port $Port

$url = "http://127.0.0.1:$Port"
Write-Host ""
Write-Host "Deep Fitness -> $url" -ForegroundColor Green
Write-Host "first build takes a minute or two; the page is blank until it finishes"
Write-Host ""
Write-Host "sign in with a seeded account, e.g. member.qa@deepfitness.app" -ForegroundColor DarkGray
Write-Host "phone sign-in will fail: only Email/Password is enabled on the project" -ForegroundColor DarkGray
Write-Host ""

if ($Open) { Start-Process $url }

$runArgs = @('run', '-d', 'web-server', '--web-port', "$Port", '--web-hostname', '127.0.0.1')
if ($Release) { $runArgs += '--release' }

& flutter @runArgs
