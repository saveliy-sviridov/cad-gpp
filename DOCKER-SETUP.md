# GPP + Démarches Simplifiées test environment setup Procedure

Setup from scratch, assuming Docker is installed and both repositories
are cloned as:

- `cad-gpp/` - GPP (Gestionnaire des Processus Projets)
- `demarches-simplifiees/` - DS (upstream Démarches Simplifiées)


## Step 1: Configure GPP

Note: we assume the workdir is the directory containing the two project directories.
Copy the example env file and fill in the required values:

```bash
cp cad-gpp/config/env.example cad-gpp/.env
```

Minimum required values in `cad-gpp/.env`:

```bash
APP_HOST="localhost:3002"
FORCE_SSL="false"
SECRET_KEY_BASE="<random string>"
INVISIBLE_CAPTCHA_SECRET="<random string>"
AR_ENCRYPTION_PRIMARY_KEY="<32-char string>"
AR_ENCRYPTION_KEY_DERIVATION_SALT="<32-char string>"
DB_PASSWORD="<password>"
```

Leave PUBLIC_DS_API_URL and PUBLIC_DS_API_TOKEN empty for now and modify the host port if necessary.


## Step 2: Configure DS

```bash
cp demarches-simplifiees/config/env.example demarches-simplifiees/.env
```

Minimum required values in `demarches-simplifiees/.env`:

```bash
APP_HOST="localhost:3003"
FORCE_SSL="false"
SECRET_KEY_BASE="<random string>"
INVISIBLE_CAPTCHA_SECRET="<random string>"
AR_ENCRYPTION_PRIMARY_KEY="<32-char string>"
AR_ENCRYPTION_KEY_DERIVATION_SALT="<32-char string>"
DB_PASSWORD="<password>"
```

## Step 3: Start both instances

```bash
# From GPP directory
PORT=3002 docker compose up --build -d
```

```bash
# From DS directory
PORT=3003 docker compose up --build -d
```

First boot takes several minutes. Both instances automatically:
- Load the database schema
- Seed the database (creates the default test user)
- *(DS only)* Compile JS/CSS assets

Monitor progress:
```bash
docker compose logs -f app
```

Wait until you see `Listening on http://0.0.0.0:3000` in the logs.

## Step 4: Fix DS email login token

DS requires an email confirmation token on every login by default. Bypass it
for the test user:

```bash
docker exec demarches-simplifiees-postgres-1 \
  psql -U tps_development -d ds_private_dev -c \
  "UPDATE instructeurs SET bypass_email_login_token = true
   WHERE id = (SELECT i.id FROM instructeurs i
               JOIN users u ON u.id = i.user_id
               WHERE u.email = 'test@exemple.fr');"
```

## Step 5: Create a procedure in DS and generate an API token

1. Log into DS at `http://localhost:3003`
2. Create a procedure (any form fields)
3. Go to **Profil → Jetons d'API** and generate a token
4. Copy the token

## Step 6: Link GPP to DS

In `cad-gpp/.env`, set:

```bash
PUBLIC_DS_API_URL="http://host.docker.internal:3003"
PUBLIC_DS_API_TOKEN="<token from step 5>"
```

Restart GPP to pick up the new values (no rebuild needed):

```bash
cd cad-gpp
PORT=3002 docker compose up -d
```

## Credentials

| Instance | URL                   | Email             | Password                          |
|----------|-----------------------|-------------------|-----------------------------------|
| GPP      | http://localhost:3002 | test@exemple.fr   | this is a very complicated password ! |
| DS       | http://localhost:3003 | test@exemple.fr   | this is a very complicated password ! |


