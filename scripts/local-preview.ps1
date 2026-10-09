param(
    [ValidateSet('start', 'stop', 'status', 'run-web', 'run-cms')]
    [string]$Action = 'start',
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$astro = Join-Path $repo 'astro'
$runtime = Join-Path $astro '.astro'
$statePath = Join-Path $runtime 'local-preview.json'
$webUrl = 'http://127.0.0.1:4321/'
$cmsUrl = 'http://127.0.0.1:4321/admin/'

function Get-Listener([int]$port) {
    return @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
}

function Test-ExpectedProcess([int]$pidToTest, [string]$role) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$pidToTest" -ErrorAction SilentlyContinue
    if (-not $process -or -not $process.CommandLine) { return $false }
    $line = [string]$process.CommandLine
    $withinProject = $line.IndexOf($astro, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
    if (-not $withinProject) { return $false }
    if ($role -eq 'web') { return $line.Contains('astro.mjs') -or $line.Contains('astro.js') }
    return $line.Contains('decap-server') -and $line.Contains('index.js')
}

function Test-ExpectedListener([int]$port, [string]$role) {
    $listeners = @(Get-Listener $port)
    if ($listeners.Count -eq 0) { return $false }
    foreach ($listener in $listeners) {
        if ($listener.LocalAddress -notin @('127.0.0.1', '::1')) {
            throw "Port $port is listening on $($listener.LocalAddress), not exclusively on localhost. Refusing to reuse it."
        }
        if (-not (Test-ExpectedProcess -pidToTest $listener.OwningProcess -role $role)) {
            throw "Port $port is used by an unrelated process (PID $($listener.OwningProcess)). Not touching it."
        }
    }
    return $true
}

function Get-State {
    if (Test-Path $statePath) {
        try {
            $saved = Get-Content -Path $statePath -Raw | ConvertFrom-Json
            return @{ web = [int]$saved.web; cms = [int]$saved.cms }
        } catch {
            Write-Warning 'Ignoring invalid local-preview.json state'
        }
    }
    return @{ web = 0; cms = 0 }
}

function Set-State($state) {
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
    $state | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $statePath
}

function Test-ManagedWrapper([int]$pidToTest, [string]$role) {
    if ($pidToTest -le 0) { return $false }
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$pidToTest" -ErrorAction SilentlyContinue
    if (-not $p -or -not $p.CommandLine) { return $false }
    return $p.CommandLine.IndexOf($PSCommandPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and
        $p.CommandLine.Contains("-Action run-$role")
}

function Start-Role([string]$role) {
    $args = '-NoExit -NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '" -Action run-' + $role
    $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WorkingDirectory $repo -PassThru
    if (-not $proc) { throw "Unable to launch $role" }
    return [int]$proc.Id
}

function Wait-ForPort([int]$port, [string]$role) {
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Milliseconds 500
        if (Test-ExpectedListener -port $port -role $role) { return }
    }
    throw "Timed out waiting for $role on port $port. Check the $role console for details."
}

function Stop-Tree([int]$pidToStop) {
    if ($pidToStop -le 0) { return }
    & taskkill.exe /PID $pidToStop /T /F 2>$null | Out-Null
}

if ($Action -in @('run-web', 'run-cms')) {
    Set-Location $astro
    try { $Host.UI.RawUI.WindowTitle = "Uke Blog | $Action" } catch {}
    $localNode = Join-Path $astro 'node_modules/node/bin/node.exe'
    if (-not (Test-Path $localNode)) { throw 'Pinned Node 22 missing. Run corepack pnpm install in astro/.' }
    if ($Action -eq 'run-web') {
        Write-Host "Uke Fuwari development server: $webUrl" -ForegroundColor Cyan
        & $localNode scripts/sync-assets.mjs
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        & $localNode node_modules/astro/astro.js dev --host 127.0.0.1 --port 4321
    } else {
        Write-Host 'Uke Decap CMS (localhost only): 127.0.0.1:8081' -ForegroundColor Cyan
        & $localNode scripts/start-cms.mjs
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Server exited with code $LASTEXITCODE. Read the error above." -ForegroundColor Red
    }
    exit $LASTEXITCODE
}

try {
    if ($Action -eq 'start') {
        if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
            throw 'Node.js/npm.cmd not found. Install Node.js 22 or use the project local environment.'
        }
        if (-not (Test-Path (Join-Path $astro 'node_modules/.bin/astro.CMD'))) {
            throw 'Fuwari dependencies missing. Open astro/ and run corepack pnpm install.'
        }
        Write-Host '=== Uke Blog: Astro local preview ===' -ForegroundColor Cyan
        $state = Get-State
        if (Test-ExpectedListener -port 4321 -role 'web') {
            Write-Host '[WEB] Existing blog server detected at port 4321.' -ForegroundColor Yellow
        } else {
            $state.web = Start-Role 'web'
            Set-State $state
            Wait-ForPort -port 4321 -role 'web'
            Write-Host '[WEB] Started live-reload development server.' -ForegroundColor Green
        }
        if (Test-ExpectedListener -port 8081 -role 'cms') {
            Write-Host '[CMS] Existing local editor service detected at port 8081.' -ForegroundColor Yellow
        } else {
            $state.cms = Start-Role 'cms'
            Set-State $state
            Wait-ForPort -port 8081 -role 'cms'
            Write-Host '[CMS] Started local-only editor service.' -ForegroundColor Green
        }
        Set-State $state
        Write-Host "Site:  $webUrl" -ForegroundColor Green
        Write-Host "CMS:   $cmsUrl" -ForegroundColor Green
        Write-Host 'Stop with stop-local.bat. Old Jekyll remains available via start-jekyll-local.bat.'
        if (-not $NoBrowser) {
            Start-Process $webUrl
            Start-Process $cmsUrl
        }
    } elseif ($Action -eq 'status') {
        foreach ($role in @('web','cms')) {
            $port = if ($role -eq 'web') { 4321 } else { 8081 }
            if (Test-ExpectedListener -port $port -role $role) {
                Write-Host "$role : running on 127.0.0.1:$port" -ForegroundColor Green
            } else {
                Write-Host "$role : stopped"
            }
        }
    } elseif ($Action -eq 'stop') {
        $state = Get-State
        foreach ($role in @('cms','web')) {
            $managed = [int]$state[$role]
            if (Test-ManagedWrapper -pidToTest $managed -role $role) {
                Write-Host "Stopping managed $role process tree $managed"
                Stop-Tree $managed
            }
            $port = if ($role -eq 'web') { 4321 } else { 8081 }
            foreach ($listener in @(Get-Listener $port)) {
                if ($listener.LocalAddress -in @('127.0.0.1','::1') -and
                    (Test-ExpectedProcess -pidToTest $listener.OwningProcess -role $role)) {
                    Write-Host "Stopping verified local $role listener PID $($listener.OwningProcess)"
                    Stop-Tree ([int]$listener.OwningProcess)
                } else {
                    Write-Warning "Port $port is owned by another process. Leaving it untouched."
                }
            }
        }
        if (Test-Path $statePath) { Remove-Item -LiteralPath $statePath -Force }
        Write-Host 'Local Astro preview stop completed.' -ForegroundColor Green
    }
    exit 0
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
