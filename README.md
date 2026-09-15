# CLIProxyAPI on Back4app Free + Neon Free

This tiny deployment wrapper runs the official `eceasy/cli-proxy-api:latest` image
on Back4app Containers and uses CLIProxyAPI's **native PostgreSQL store** for
persistent config and OAuth credentials.

No custom sync daemon is required.

## 1. Create a Neon database

1. Sign up at Neon.
2. Create a project/database.
3. Copy the **pooled PostgreSQL connection string**.
4. Make sure it ends with (or otherwise enables) `sslmode=require`.

Example only:

```text
postgresql://user:password@ep-example-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require
```

Never commit the real DSN to GitHub.

## 2. Put this folder in a GitHub repository

The repository only needs:

```text
Dockerfile
start.sh
README.md
```

There are no secrets in the repository.

## 3. Create the Back4app Container

In Back4app:

1. Build new app / New App
2. Containers / Web Deployment
3. Connect GitHub
4. Select this repository
5. Use the Free plan
6. Set the service port to **8317** if Back4app asks for it.

Add these environment variables:

```text
PGSTORE_DSN=<your Neon pooled connection string>
PGSTORE_SCHEMA=public
PGSTORE_LOCAL_PATH=/tmp/cpa
MANAGEMENT_PASSWORD=<a long random secret>
PROXY_API_KEY=<another long random secret>
```

Use different values for `MANAGEMENT_PASSWORD` and `PROXY_API_KEY`.

For `PROXY_API_KEY`, use a 32-byte/64-character hex string. For example:

```bash
openssl rand -hex 32
```

The wrapper intentionally restricts this key to letters, digits, `.`, `_`, and `-`
so it can be inserted into YAML safely.

## 4. Deploy

After the deployment is ready, Back4app gives you an HTTPS URL similar to:

```text
https://your-app-name.b4a.run
```

Open the management UI:

```text
https://your-app-name.b4a.run/management.html
```

Log in with `MANAGEMENT_PASSWORD`.

Your API base URL is:

```text
https://your-app-name.b4a.run/v1
```

Your client API key is `PROXY_API_KEY`.

## 5. Add OAuth accounts

Use the management UI's OAuth page for Codex, Claude, Antigravity, etc.

CLIProxyAPI writes the resulting auth records to its native PostgreSQL store.
The local `/tmp/cpa/...` files are only an ephemeral mirror.

When Back4app replaces/restarts the container, CLIProxyAPI restores the config
and auth records from Neon.

## Important notes

- Use **one Back4app replica only**. CLIProxyAPI's PostgreSQL backend is not meant
  to synchronize the same OAuth credential across multiple live replicas.
- Keep `PGSTORE_DSN`, `MANAGEMENT_PASSWORD`, and `PROXY_API_KEY` only in Back4app
  environment variables.
- A fresh Neon project is easiest for the first deployment.
- If a previous failed CPA deployment already seeded an unsafe example config
  into the database, delete that Neon project and create a fresh one, or delete
  the `config` row from `public.config_store` before retrying.
- Back4app Free currently has tight RAM/CPU limits. If the container reports OOM,
  reduce concurrency/providers; persistence is not the cause.
