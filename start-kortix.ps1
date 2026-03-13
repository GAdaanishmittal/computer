#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start Kortix Platform services
.DESCRIPTION
    Starts Supabase, Sandbox, API, and Frontend services with automatic onboarding bypass
#>

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Kortix Platform..." -ForegroundColor Cyan

# Check if Docker is running
try {
    docker ps | Out-Null
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Start Supabase stack
Write-Host "`n📦 Starting Supabase stack..." -ForegroundColor Yellow
Push-Location infra/supabase
try {
    supabase start
    if ($LASTEXITCODE -ne 0) {
        throw "Supabase failed to start"
    }
} finally {
    Pop-Location
}

# Start Sandbox
Write-Host "`n🖥️  Starting Kortix Sandbox..." -ForegroundColor Yellow
$sandboxRunning = docker ps --filter "name=kortix-sandbox" --format "{{.Names}}" | Select-String "kortix-sandbox"
if (-not $sandboxRunning) {
    docker start kortix-sandbox 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creating new sandbox container..." -ForegroundColor Gray
        docker run -d `
            --name kortix-sandbox `
            --hostname kortix-sandbox `
            -p 14000:8000 `
            -p 14001:3111 `
            -p 14002:6080 `
            -p 14003:6081 `
            -p 14004:3210 `
            -p 14005:9223 `
            -p 14006:9224 `
            -p 14007:22 `
            -p 14008:3211 `
            -v kortix-workspace:/workspace `
            -e INTERNAL_SERVICE_KEY=33267421f64dad95db7ad5a76a4e7088f76f1324f6339116f6aaed4b053c020b `
            kortix/sandbox:latest
    }
}

# Wait for sandbox to be healthy
Write-Host "Waiting for sandbox to be ready..." -ForegroundColor Gray
$maxAttempts = 30
$attempt = 0
while ($attempt -lt $maxAttempts) {
    $health = docker inspect kortix-sandbox --format='{{.State.Health.Status}}' 2>$null
    if ($health -eq "healthy") {
        break
    }
    Start-Sleep -Seconds 2
    $attempt++
}

if ($attempt -eq $maxAttempts) {
    Write-Host "⚠️  Sandbox health check timeout, but continuing..." -ForegroundColor Yellow
}

# Apply database migrations
Write-Host "`n📊 Applying database migrations..." -ForegroundColor Yellow
Get-ChildItem "infra/supabase/migrations/*.sql" | Sort-Object Name | ForEach-Object {
    Write-Host "  Applying: $($_.Name)" -ForegroundColor Gray
    Get-Content $_.FullName | docker exec -i supabase_db_kortix-local psql -U postgres -d postgres -q
}

# Update sandbox record in database
Write-Host "`n🔧 Configuring sandbox in database..." -ForegroundColor Yellow
$updateSandboxQuery = @"
UPDATE kortix.sandboxes 
SET status = 'active', 
    external_id = 'kortix-sandbox', 
    base_url = 'http://kortix-sandbox:8000',
    metadata = jsonb_build_object(
        'mappedPorts', jsonb_build_object(
            '8000', 14000, '3111', 14001, '6080', 14002, '6081', 14003,
            '3210', 14004, '9223', 14005, '9224', 14006, '22', 14007, '3211', 14008
        )
    )
WHERE sandbox_id = (SELECT sandbox_id FROM kortix.sandboxes ORDER BY created_at DESC LIMIT 1);

DELETE FROM kortix.sandboxes WHERE status = 'error';

UPDATE kortix.accounts 
SET setup_complete_at = NOW(), 
    setup_wizard_step = 3 
WHERE setup_complete_at IS NULL;
"@

docker exec supabase_db_kortix-local psql -U postgres -d postgres -c $updateSandboxQuery -q

# Fix secrets file in sandbox
Write-Host "`n🔐 Initializing secrets store..." -ForegroundColor Yellow
$secretsJson = '{"secrets":{},"version":1}'
$bytes = [System.Text.Encoding]::UTF8.GetBytes($secretsJson)
$base64 = [Convert]::ToBase64String($bytes)
docker exec kortix-sandbox sh -c "echo $base64 | base64 -d > /workspace/.secrets/.secrets.json && chmod 600 /workspace/.secrets/.secrets.json"

# Set ONBOARDING_COMPLETE in s6 env
docker exec kortix-sandbox sh -c 'echo "true" > /var/run/s6/container_environment/ONBOARDING_COMPLETE'

# Kill any processes on ports 8008 and 3000
Write-Host "`n🧹 Cleaning up ports..." -ForegroundColor Yellow
$ports = @(8008, 3000)
foreach ($port in $ports) {
    $processIds = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess | Select-Object -Unique
    foreach ($procId in $processIds) {
        if ($procId -ne 0) {
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        }
    }
}

Start-Sleep -Seconds 1

# Start API
Write-Host "`n🔌 Starting Kortix API..." -ForegroundColor Yellow
Push-Location kortix-api
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "bun run src/index.ts" -WindowStyle Minimized
Pop-Location

Start-Sleep -Seconds 3

# Start Frontend
Write-Host "`n🌐 Starting Frontend..." -ForegroundColor Yellow
Push-Location apps/frontend
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "npm run dev" -WindowStyle Minimized
Pop-Location

Write-Host "`n✅ Kortix Platform is starting!" -ForegroundColor Green
Write-Host "`nServices:" -ForegroundColor Cyan
Write-Host "  • Supabase Studio:  http://localhost:64323" -ForegroundColor White
Write-Host "  • Supabase API:     http://localhost:64321" -ForegroundColor White
Write-Host "  • Database:         postgresql://postgres:postgres@127.0.0.1:64322/postgres" -ForegroundColor White
Write-Host "  • Kortix API:       http://localhost:8008" -ForegroundColor White
Write-Host "  • Frontend:         http://localhost:3000" -ForegroundColor White
Write-Host "  • Sandbox Desktop:  http://localhost:14002" -ForegroundColor White

Write-Host "`n⏳ Waiting for services to be ready..." -ForegroundColor Gray
Start-Sleep -Seconds 8

Write-Host "`n🎉 Opening dashboard..." -ForegroundColor Green
Start-Process "http://localhost:3000/onboarding?skip_onboarding"

Write-Host "`nℹ️  To stop services:" -ForegroundColor Gray
Write-Host "  • API & Frontend: Close the PowerShell windows" -ForegroundColor Gray
Write-Host "  • Supabase: cd infra/supabase && supabase stop" -ForegroundColor Gray
Write-Host "  • Sandbox: docker stop kortix-sandbox" -ForegroundColor Gray
