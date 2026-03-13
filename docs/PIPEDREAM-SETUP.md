# Pipedream Integration Setup

Complete guide to configure Pipedream Connect for OAuth integrations with 2000+ apps.

## What is Pipedream Connect?

Pipedream Connect is an OAuth integration platform that allows your Kortix agents to connect with external services like Gmail, Slack, GitHub, Notion, and 2000+ other apps. It handles the OAuth flow, token management, and provides a unified API for all integrations.

## Setup Steps

### 1. Create Pipedream Account

1. Visit https://pipedream.com/connect
2. Sign up for a free account (no credit card required)
3. You'll be redirected to the Connect dashboard

### 2. Create a Project

1. Click **"New Project"** in the Connect dashboard
2. Enter a project name (e.g., "Kortix Development" or "Kortix Production")
3. Click **Create**
4. You'll see your project dashboard

### 3. Get Project ID

1. In your project, click **Settings** (gear icon)
2. Copy the **Project ID** (format: `prj_xxxxx`)
3. Save this for later

### 4. Create OAuth Client

1. In project settings, go to **OAuth Clients** tab
2. Click **"New OAuth Client"**
3. Fill in the details:
   - **Name**: `Kortix Local` (or any name you prefer)
   - **Redirect URIs**: Add both of these:
     ```
     http://localhost:3000/integrations/callback
     http://localhost:8008/v1/integrations/callback
     ```
   - **Description**: Optional
4. Click **Create**
5. You'll see your credentials:
   - **Client ID**: `pc_xxxxx`
   - **Client Secret**: `pcs_xxxxx` (click "Show" to reveal)
6. Copy both values - you'll need them next

### 5. Configure Kortix

Edit the `.env` file in your Kortix root directory:

```env
# Change from 'none' to 'pipedream'
INTEGRATION_AUTH_PROVIDER=pipedream

# Add your Pipedream credentials
PIPEDREAM_CLIENT_ID=pc_xxxxxxxxxxxxx
PIPEDREAM_CLIENT_SECRET=pcs_xxxxxxxxxxxxx
PIPEDREAM_PROJECT_ID=prj_xxxxxxxxxxxxx
PIPEDREAM_ENVIRONMENT=development
```

**Important**: 
- Use `development` environment for local testing
- Use `production` environment for deployed instances
- Keep your Client Secret secure - never commit it to version control

### 6. Restart Kortix

```powershell
# Windows
.\stop-kortix.ps1
.\start-kortix.ps1

# Or restart just the API
# Stop the API (Ctrl+C in its terminal)
cd kortix-api
bun run src/index.ts
```

### 7. Test the Integration

1. Open Kortix dashboard: http://localhost:3000
2. Navigate to **Integrations** in the sidebar
3. You should see a list of available apps (no more "Failed to load" error)
4. Click **Connect** on any app (e.g., Gmail)
5. Complete the OAuth authorization flow
6. The connection will appear in your connected apps list

## Using Integrations in Agents

Once you've connected an app, your agents can use it:

### Example: Gmail Integration

```typescript
// Agent can now send emails via Gmail
await sendEmail({
  to: "user@example.com",
  subject: "Hello from Kortix",
  body: "This email was sent by my agent!"
});
```

### Example: Slack Integration

```typescript
// Agent can post to Slack channels
await postToSlack({
  channel: "#general",
  message: "Task completed successfully!"
});
```

### Example: GitHub Integration

```typescript
// Agent can create issues, PRs, etc.
await createGitHubIssue({
  repo: "myorg/myrepo",
  title: "Bug found by agent",
  body: "Details of the bug..."
});
```

## Available Apps

Pipedream Connect supports 2000+ apps across categories:

### Communication & Collaboration
- **Email**: Gmail, Outlook, SendGrid, Mailgun
- **Chat**: Slack, Discord, Microsoft Teams, Telegram
- **Video**: Zoom, Google Meet

### Productivity & Project Management
- **Notes**: Notion, Evernote, OneNote
- **Spreadsheets**: Google Sheets, Airtable, Excel
- **Tasks**: Trello, Asana, Monday.com, ClickUp, Todoist
- **Documents**: Google Docs, Dropbox, Box

### Development & DevOps
- **Version Control**: GitHub, GitLab, Bitbucket
- **CI/CD**: Vercel, Netlify, CircleCI, Jenkins
- **Issue Tracking**: Jira, Linear, GitHub Issues
- **Monitoring**: Datadog, New Relic, Sentry

### CRM & Sales
- **CRM**: Salesforce, HubSpot, Pipedrive, Zoho
- **Payments**: Stripe, PayPal, Square
- **E-commerce**: Shopify, WooCommerce

### Marketing & Social Media
- **Email Marketing**: Mailchimp, ConvertKit, ActiveCampaign
- **Social**: Twitter, LinkedIn, Facebook, Instagram
- **Analytics**: Google Analytics, Mixpanel

### Databases & Storage
- **Databases**: PostgreSQL, MySQL, MongoDB, Supabase
- **Storage**: AWS S3, Google Cloud Storage, Azure Blob
- **APIs**: REST APIs, GraphQL

## Troubleshooting

### "Failed to load available apps"

**Cause**: Pipedream credentials not configured or incorrect

**Solution**:
1. Verify `INTEGRATION_AUTH_PROVIDER=pipedream` in `.env`
2. Check all three credentials are set:
   - `PIPEDREAM_CLIENT_ID`
   - `PIPEDREAM_CLIENT_SECRET`
   - `PIPEDREAM_PROJECT_ID`
3. Restart the API
4. Check API logs for specific errors

### OAuth Callback Errors

**Cause**: Redirect URI mismatch

**Solution**:
1. Go to Pipedream project → Settings → OAuth Clients
2. Verify these exact URLs are added:
   ```
   http://localhost:3000/integrations/callback
   http://localhost:8008/v1/integrations/callback
   ```
3. Check for typos (http vs https, trailing slashes, etc.)
4. For production, add your production URLs

### "Invalid Client" Error

**Cause**: Wrong Client ID or Client Secret

**Solution**:
1. Go to Pipedream project → Settings → OAuth Clients
2. Click "Show" to reveal the Client Secret
3. Copy the exact values (no extra spaces)
4. Update `.env` file
5. Restart the API

### Connection Not Saving

**Cause**: Database or API issue

**Solution**:
1. Check database is running:
   ```powershell
   docker ps | grep supabase
   ```
2. Check API logs for errors
3. Verify the connection in Supabase Studio:
   - Open http://localhost:64323
   - Navigate to Table Editor → kortix.integrations
   - Check if the connection was created

### Environment Mismatch

**Cause**: Using wrong Pipedream environment

**Solution**:
- For local development: `PIPEDREAM_ENVIRONMENT=development`
- For production: `PIPEDREAM_ENVIRONMENT=production`
- Connections are environment-specific
- Restart API after changing environment

## Security Best Practices

### Protect Your Credentials

1. **Never commit credentials to Git**
   - `.env` is in `.gitignore` by default
   - Use `.env.example` for templates

2. **Use environment-specific credentials**
   - Separate projects for dev/staging/production
   - Different OAuth clients for each environment

3. **Rotate credentials regularly**
   - Generate new Client Secret periodically
   - Update `.env` and restart services

4. **Limit redirect URIs**
   - Only add necessary URLs
   - Remove unused redirect URIs

### Token Management

- Pipedream handles token refresh automatically
- Tokens are stored encrypted in your database
- Users can revoke access anytime from their connected accounts

## Production Deployment

When deploying to production:

1. **Create a production Pipedream project**
   ```
   Project Name: Kortix Production
   Environment: production
   ```

2. **Add production redirect URIs**
   ```
   https://yourdomain.com/integrations/callback
   https://api.yourdomain.com/v1/integrations/callback
   ```

3. **Update production environment variables**
   ```env
   INTEGRATION_AUTH_PROVIDER=pipedream
   PIPEDREAM_CLIENT_ID=pc_prod_xxxxx
   PIPEDREAM_CLIENT_SECRET=pcs_prod_xxxxx
   PIPEDREAM_PROJECT_ID=prj_prod_xxxxx
   PIPEDREAM_ENVIRONMENT=production
   ```

4. **Use HTTPS in production**
   - Pipedream requires HTTPS for production OAuth
   - Set up SSL certificates (Let's Encrypt recommended)

## Pricing

Pipedream Connect pricing (as of 2024):

- **Free Tier**: 
  - 100 connected accounts
  - 10,000 API requests/month
  - Perfect for development and small deployments

- **Paid Tiers**: 
  - More connected accounts
  - Higher API limits
  - Priority support
  - See https://pipedream.com/pricing for current pricing

## Alternative: Custom OAuth

If you don't want to use Pipedream, you can implement custom OAuth:

1. Set `INTEGRATION_AUTH_PROVIDER=none` in `.env`
2. Implement OAuth flows directly in your code
3. Store tokens in the database manually
4. Handle token refresh logic

This requires more development work but gives you full control.

## Support

- **Pipedream Docs**: https://pipedream.com/docs/connect
- **Pipedream Support**: support@pipedream.com
- **Kortix Issues**: https://github.com/kortix-ai/computer/issues

## Quick Reference

### Environment Variables

```env
INTEGRATION_AUTH_PROVIDER=pipedream
PIPEDREAM_CLIENT_ID=pc_xxxxxxxxxxxxx
PIPEDREAM_CLIENT_SECRET=pcs_xxxxxxxxxxxxx
PIPEDREAM_PROJECT_ID=prj_xxxxxxxxxxxxx
PIPEDREAM_ENVIRONMENT=development
```

### Redirect URIs (Local)

```
http://localhost:3000/integrations/callback
http://localhost:8008/v1/integrations/callback
```

### Redirect URIs (Production)

```
https://yourdomain.com/integrations/callback
https://api.yourdomain.com/v1/integrations/callback
```

### Useful Commands

```powershell
# Check if Pipedream is configured
Get-Content .env | Select-String "PIPEDREAM"

# Restart API to apply changes
cd kortix-api
bun run src/index.ts

# Check API logs for integration errors
# (visible in the terminal where API is running)

# View connected integrations in database
docker exec -it supabase_db_kortix-local psql -U postgres -d postgres -c "SELECT * FROM kortix.integrations;"
```
