# Helper MCP server

Remote MCP server that lets Claude (web, desktop, mobile) read/write the Helper
app's Firestore data (`users/{uid}/…`). Auth is a secret token in the URL.

## Deploy (Vercel, separate project)
1. Firebase console → Project settings → Service accounts → Generate new private key.
2. Find your UID: Firebase console → Authentication → Users.
3. `cd mcp-server && npx vercel` (set root to this folder), then add env vars:
   - `FIREBASE_SERVICE_ACCOUNT` – the full service-account JSON, as one line
   - `FIREBASE_UID` – your Firebase Auth UID
   - `MCP_TOKEN` – long random string (`openssl rand -hex 32`)
4. `npx vercel --prod`
5. claude.ai → Settings → Connectors → Add custom connector →
   `https://<project>.vercel.app/mcp/<MCP_TOKEN>`
   It then appears in the Claude mobile app too.

Treat the URL like a password; rotate `MCP_TOKEN` to revoke access.
Never commit the service-account JSON.
