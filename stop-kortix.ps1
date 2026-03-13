#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Stop Kortix Platform services
.DESCRIPTION
    Stops all Kortix services (API, Frontend, Sandbox, Supabase)
#>

$ErrorActionPreference = "Continue"

Write-Host "🛑 Stopping Kortix Platform..." -ForegroundColor Cyan

# Stop processes on ports 8008 and 3000
Write-Host "`n🔌 Stopping API and Frontend..." -ForegroundColor Yellow
$ports = @(8008, 3000)
foreach ($port in $ports) {
    $processIds = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess | Select-Object -Unique
    foreach ($procId in $processIds) {
        if ($procId -ne 0) {
            try {
                $process = Get-Process -Id $procId -ErrorAction SilentlyContinue
                if ($process) {
                    Write-Host "  Stopping process on port $port (PID: $procId)" -ForegroundColor Gray
                    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                }
            } catch {}
        }
    }
}

# Stop Sandbox
Write-Host "`n🖥️  Stopping Kortix Sandbox..." -ForegroundColor Yellow
docker stop kortix-sandbox 2>$null | Out-Null

# Stop Supabase
Write-Host "`n📦 Stopping Supabase stack..." -ForegroundColor Yellow
Push-Location infra/supabase
try {
    supabase stop
} catch {
    Write-Host "  Supabase already stopped or not running" -ForegroundColor Gray
} finally {
    Pop-Location
}

Write-Host "`n✅ Kortix Platform stopped!" -ForegroundColor Green
