# Kortix Platform - Windows Setup Guide

Complete guide to set up and run Kortix Platform on Windows.

## Prerequisites

### Required Software

1. **Docker Desktop for Windows**
   - Download: https://www.docker.com/products/docker-desktop/
   - Minimum version: 4.0+
   - Enable WSL 2 backend (recommended)
   - Allocate at least 8GB RAM and 4 CPU cores in Docker settings

2. **Node.js**
   - Download: https://nodejs.org/ (LTS version recommended)
   - Minimum version: 18.x
   - Verify: `node --version`

3. **Bun Runtime**
   - Download: https://bun.sh/
   - Install via PowerShell: `powershell -c "irm bun.sh/install.ps1|iex"`
   - Verify: `bun --version`

4. **Supabase CLI**
   - Install via npm: `npm install -g supabase`
   - Or via Scoop: `scoop install supabase`
   - Verify: `supabase --version`

5. **Git**
   - Download: https://git-scm.com/download/win
   - Verify: `git --version`

### Optional but Recommended

- **Windows Terminal** (for better PowerShell experience)
- **Visual Studio Code** (for editing configuration files)

## Installation Steps

### 1. Clone the Repository

```powershell
git clone https://github.com/kortix-ai/computer.git
cd computer
```

### 2. Install Dependencies

```powershell
# Install Node.js dependencies
npm install -g pnpm
pnpm install

# Install frontend dependencies
cd apps/frontend
npm install
cd ../..

# Install API dependencies
cd kortix-api
bun install
cd ..
```

### 3. Configure Environment Variables

The `.env` file in the root directory contains all configuration. Key settings for local development:

```env
# Core
ENV_MODE=local
FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:8008/v1

# Database (auto-configured by Supabase)
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:64322/postgres
SUPABASE_URL=http://127.0.0.1:64321

# Integrations (disable for local dev)
INTEGRATION_AUTH_PROVIDER=none

# LLM Providers (add your API keys)
OPENROUTER_API_KEY=your-key-here
OPENAI_API_KEY=your-key-here

# Optional: Search providers
FIRECRAWL_API_KEY=your-key-here
TAVILY_API_KEY=your-key-here
```

### 4. Start Services

#### Option A: Automated Startup (Recommended)

```powershell
.\start-kortix.ps1
```

This script will:
- Start Supabase stack (database, API, Studio)
- Start or create the Kortix sandbox container
- Apply database migrations
- Configure environment variables
- Initialize secrets store
- Fix Agent Browser paths
- Start API and Frontend servers
- Open the dashboard in your browser

#### Option B: Manual Startup

If you prefer to start services manually:

```powershell
# 1. Start Supabase
cd infra/supabase
supabase start
cd ../..

# 2. Start Sandbox
docker start kortix-sandbox
# Or create if it doesn't exist:
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
  kortix/computer:latest

# 3. Apply Database Migrations
Get-ChildItem "infra/supabase/migrations/*.sql" | Sort-Object Name | ForEach-Object {
    Get-Content $_.FullName | docker exec -i supabase_db_kortix-local psql -U postgres -d postgres -q
}

# 4. Start API
cd kortix-api
bun run src/index.ts
# Keep this terminal open

# 5. Start Frontend (in a new terminal)
cd apps/frontend
npm run dev
# Keep this terminal open
```

### 5. Access the Platform

Once all services are running:

- **Dashboard**: http://localhost:3000
- **API**: http://localhost:8008
- **Supabase Studio**: http://localhost:64323
- **Sandbox Desktop**: http://localhost:14002
- **Agent Browser**: http://localhost:14006

First-time access will redirect to onboarding. The automated script bypasses this automatically.

## Service Management

### Check Service Status

```powershell
# Check Docker containers
docker ps

# Check Supabase status
cd infra/supabase
supabase status
cd ../..

# Check if ports are in use
Get-NetTCPConnection -LocalPort 3000,8008,64321,64322,64323 | Select-Object LocalPort,State
```

### Stop Services

```powershell
# Option A: Automated
.\stop-kortix.ps1

# Option B: Manual
# Stop API and Frontend (Ctrl+C in their terminals)

# Stop Sandbox
docker stop kortix-sandbox

# Stop Supabase
cd infra/supabase
supabase stop
cd ../..
```

### Restart Services

```powershell
# Full restart
.\stop-kortix.ps1
.\start-kortix.ps1

# Restart individual services
docker restart kortix-sandbox
# Then restart API and Frontend
```

## Troubleshooting

### Port Already in Use

If you get "port already in use" errors:

```powershell
# Kill process on specific port (e.g., 8008)
$port = 8008
$processIds = (Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).OwningProcess | Select-Object -Unique
foreach ($procId in $processIds) {
    if ($procId -ne 0) {
        Stop-Process -Id $procId -Force
    }
}
```

### Docker Not Running

```powershell
# Check Docker status
docker ps

# If error, start Docker Desktop manually
# Then wait for it to fully start before running scripts
```

### Supabase Won't Start

```powershell
# Reset Supabase
cd infra/supabase
supabase stop
supabase start
cd ../..
```

### Database Migration Errors

```powershell
# Reapply migrations
Get-ChildItem "infra/supabase/migrations/*.sql" | Sort-Object Name | ForEach-Object {
    Write-Host "Applying: $($_.Name)"
    Get-Content $_.FullName | docker exec -i supabase_db_kortix-local psql -U postgres -d postgres
}
```

### Sandbox Container Issues

```powershell
# Remove and recreate sandbox
docker stop kortix-sandbox
docker rm kortix-sandbox
docker volume rm kortix-workspace

# Then run start-kortix.ps1 again
```

### Agent Browser Not Working

```powershell
# Fix browser viewer path
docker exec kortix-sandbox sh -c 'ln -sf /opt/build/browser-viewer /opt/agent-browser-viewer'
docker exec kortix-sandbox sh -c 's6-svc -u /run/service/svc-agent-browser-viewer'
```

### Frontend Build Errors

```powershell
# Clear Next.js cache
cd apps/frontend
Remove-Item -Recurse -Force .next
npm run dev
cd ../..
```

### API Connection Errors

Check that all environment variables are set correctly in `.env`:

```powershell
# Verify critical variables
Get-Content .env | Select-String "DATABASE_URL|SUPABASE_URL|INTEGRATION_AUTH_PROVIDER"
```

## Configuration

### Adding LLM Provider Keys

Edit `.env` and add your API keys:

```env
OPENROUTER_API_KEY=sk-or-v1-...
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
```

Restart the API after changing keys:
```powershell
# Stop API (Ctrl+C in its terminal)
cd kortix-api
bun run src/index.ts
```

### Adding Search Provider Keys

For web search and scraping features:

```env
FIRECRAWL_API_KEY=fc-...
TAVILY_API_KEY=tvly-...
SERPER_API_KEY=...
```

### Configuring Pipedream Integrations

Pipedream provides OAuth integration for 2000+ apps (Gmail, Slack, GitHub, Notion, etc.).

#### Step 1: Create a Pipedream Account

1. Go to https://pipedream.com/connect
2. Sign up for a free account
3. Navigate to the Connect dashboard

#### Step 2: Create a Connect Project

1. In Pipedream Connect, click "New Project"
2. Give it a name (e.g., "Kortix Local Dev")
3. Note down the **Project ID** from the project settings

#### Step 3: Get API Credentials

1. In your Pipedream project, go to **Settings** → **API Keys**
2. Create a new OAuth client:
   - **Client Name**: Kortix Local
   - **Redirect URIs**: Add these URLs:
     ```
     http://localhost:3000/integrations/callback
     http://localhost:8008/v1/integrations/callback
     ```
3. Save and note down:
   - **Client ID**
   - **Client Secret**

#### Step 4: Configure Environment Variables

Edit `.env` in the root directory:

```env
# Enable Pipedream integrations
INTEGRATION_AUTH_PROVIDER=pipedream

# Add your Pipedream credentials
PIPEDREAM_CLIENT_ID=your-client-id-here
PIPEDREAM_CLIENT_SECRET=your-client-secret-here
PIPEDREAM_PROJECT_ID=your-project-id-here
PIPEDREAM_ENVIRONMENT=development
```

#### Step 5: Restart Services

```powershell
# Stop services
.\stop-kortix.ps1

# Start services
.\start-kortix.ps1
```

Or restart just the API:
```powershell
# Stop API (Ctrl+C in its terminal)
cd kortix-api
bun run src/index.ts
```

#### Step 6: Connect Apps

1. Open the dashboard: http://localhost:3000
2. Go to **Integrations** in the sidebar
3. Click **Connect** on any app (Gmail, Slack, etc.)
4. Follow the OAuth flow to authorize the app
5. The connection will be saved and available to your agents

#### Available Apps

Pipedream Connect supports 2000+ apps including:

**Communication**
- Gmail, Outlook, Slack, Discord, Telegram, WhatsApp

**Productivity**
- Notion, Airtable, Google Sheets, Trello, Asana

**Development**
- GitHub, GitLab, Jira, Linear, Vercel

**CRM & Sales**
- HubSpot, Salesforce, Pipedrive, Stripe

**Marketing**
- Mailchimp, SendGrid, Twitter, LinkedIn

**And many more...**

#### Troubleshooting Pipedream

**"Failed to load available apps" error:**
- Verify `INTEGRATION_AUTH_PROVIDER=pipedream` in `.env`
- Check that all Pipedream credentials are set correctly
- Restart the API after changing credentials

**OAuth callback errors:**
- Ensure redirect URIs are added in Pipedream project settings
- Check that the URLs match exactly (including http/https)
- Verify the frontend URL matches `FRONTEND_URL` in `.env`

**Connection not saving:**
- Check API logs for errors
- Verify database is running: `docker ps | grep supabase`
- Check Pipedream project has correct environment (development/production)

### Disabling Features

To disable optional features, edit `.env`:

```env
# Disable integrations (use 'none' instead of 'pipedream')
INTEGRATION_AUTH_PROVIDER=none

# Disable billing
NEXT_PUBLIC_BILLING_ENABLED=false

# Disable channels
CHANNELS_ENABLED=false

# Disable tunnel
TUNNEL_ENABLED=false
```

## Development Workflow

### Making Code Changes

1. **Frontend changes**: Hot reload is automatic
2. **API changes**: Restart the API process (Ctrl+C, then `bun run src/index.ts`)
3. **Sandbox changes**: Rebuild the sandbox image (advanced)

### Viewing Logs

```powershell
# API logs: visible in the terminal where you ran bun
# Frontend logs: visible in the terminal where you ran npm run dev

# Sandbox logs
docker logs kortix-sandbox --tail 100 --follow

# Supabase logs
cd infra/supabase
supabase logs
cd ../..
```

### Database Access

```powershell
# Via Supabase Studio
# Open http://localhost:64323

# Via psql
docker exec -it supabase_db_kortix-local psql -U postgres -d postgres

# Example queries
# List tables: \dt kortix.*
# Query accounts: SELECT * FROM kortix.accounts;
```

## Performance Optimization

### Docker Resource Allocation

1. Open Docker Desktop
2. Go to Settings → Resources
3. Recommended settings:
   - CPUs: 4+
   - Memory: 8GB+
   - Swap: 2GB
   - Disk image size: 64GB+

### Windows Defender Exclusions

Add these folders to Windows Defender exclusions for better performance:

1. Open Windows Security → Virus & threat protection → Manage settings
2. Add exclusions:
   - `C:\kortix computer\computer` (or your installation path)
   - `C:\Users\<YourUser>\.docker`
   - Docker Desktop installation folder

## Security Notes

### API Keys

- Never commit `.env` files to version control
- Rotate exposed API keys immediately
- Use environment-specific keys (dev vs production)

### Network Access

- By default, services are only accessible from localhost
- To expose externally, configure firewall rules carefully
- Use HTTPS in production environments

## Getting Help

- **Documentation**: Check the main README.md
- **Issues**: https://github.com/kortix-ai/computer/issues
- **Logs**: Always check service logs when troubleshooting

## Quick Reference

### Common Commands

```powershell
# Start everything
.\start-kortix.ps1

# Stop everything
.\stop-kortix.ps1

# Check status
docker ps
supabase status

# View logs
docker logs kortix-sandbox --tail 50
docker logs supabase_db_kortix-local --tail 50

# Restart sandbox
docker restart kortix-sandbox

# Clean restart
.\stop-kortix.ps1
docker volume rm kortix-workspace
.\start-kortix.ps1
```

### Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Dashboard | http://localhost:3000 | Main UI |
| API | http://localhost:8008 | Backend API |
| Supabase Studio | http://localhost:64323 | Database UI |
| Supabase API | http://localhost:64321 | Auth & Database API |
| Database | postgresql://postgres:postgres@127.0.0.1:64322/postgres | Direct DB access |
| Sandbox Desktop | http://localhost:14002 | Virtual desktop |
| Agent Browser | http://localhost:14006 | Browser viewer |

### Port Reference

| Port | Service |
|------|---------|
| 3000 | Frontend |
| 8008 | API |
| 14000 | Sandbox (kortix-master) |
| 14001 | Sandbox (OpenCode) |
| 14002 | Sandbox (Desktop VNC) |
| 14003 | Sandbox (Desktop WebRTC) |
| 14004 | Sandbox (OpenCode Web) |
| 14005 | Sandbox (Browser Stream) |
| 14006 | Sandbox (Browser Viewer) |
| 14007 | Sandbox (SSH) |
| 14008 | Sandbox (OpenCode Channels) |
| 64321 | Supabase API |
| 64322 | PostgreSQL |
| 64323 | Supabase Studio |
