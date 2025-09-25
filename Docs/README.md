# Inputly
 
A lightweight Node.js/Express authentication starter that uses Drizzle ORM with Postgres (Neon), Zod validation, JWT-based sessions stored in httpOnly cookies, and structured logging with Winston.

## Features
- **Register/Login/Logout** flows
- **httpOnly cookie** session with JWT
- **Zod** request validation
- **Drizzle ORM** (Postgres) with migrations via drizzle-kit
- **Bcrypt** password hashing
- **Winston** logging
- **Express 5**, CORS, Helmet, Cookie-Parser

## Tech Stack
- Runtime: Node.js (ESM)
- Web: Express 5
- DB/ORM: Drizzle ORM + Postgres (Neon serverless)
- Validation: Zod
- Auth: JSON Web Tokens (JWT) + httpOnly cookies
- Security: Helmet, CORS
- Logging: Winston

## Project Structure
```
src/
  app/
  config/
  controllers/
    auth.controller.js
  middleware/
  models/
    user.model.js
  routes/
    auth.routes.js
  services/
    auth.service.js
  utils/
    cookies.js
    jwt.js
  validations/
    auth.validation.js
```

## Getting Started

### Prerequisites
- Node.js 18+
- A Postgres database (Neon recommended)

### Install
```
npm install
```

### Environment Variables
Create a `.env` file in the project root:
```
# Server
PORT=3000
NODE_ENV=development

# Auth
JWT_SECRET=replace_with_a_strong_secret
JWT_EXPIRES_IN=7d

# Database (Neon example)
DATABASE_URL=postgres://user:password@host:port/dbname
```

Ensure your app loads env vars in `src/config` (not shown here). Drizzle connects using `DATABASE_URL`.

## Database
Generate and run migrations with drizzle-kit:
```
npm run db:generate
npm run db:migrate
npm run db:studio    # optional visual browser
```

The `users` table is defined in `src/models/user.model.js`.

## Run the App
```
npm run dev
```
By default the server runs with: `node --watch src/index.js` (see `package.json`).

## Docker

This project includes first-class Docker support for both development with Neon Local and production with Neon Cloud.

### Files
- `Dockerfile` — Multi-stage container with `dev` and `prod` targets.
- `docker-compose.dev.yml` — Runs the app and Neon Local proxy (for ephemeral branches) in development.
- `docker-compose.prod.yml` — Runs the app only, connecting to Neon Cloud via `DATABASE_URL`.
- `.env.development.example` — Template for local development.
- `.env.production.example` — Template for production deployment.

### Development with Neon Local
Neon Local runs a local proxy to your Neon project and can create ephemeral branches for development/testing.

1) Copy and fill your environment
```
cp .env.development.example .env.development
# Set NEON_API_KEY, NEON_PROJECT_ID, optional PARENT_BRANCH_ID
# Optionally adjust DATABASE_URL (service hostname must be `neon-local` inside compose)
```

2) Start the stack
```
docker compose -f docker-compose.dev.yml up --build
```

This brings up two services:
- `neon-local` (image `neondatabase/neon_local:latest`) on port 5432
- `app` (Inputly) on port 3000

The app uses `DATABASE_URL=postgres://neon:npg@neon-local:5432/app?sslmode=require` inside the compose network. For JavaScript Postgres clients, Neon Local uses a self-signed certificate; ensure your driver config allows it (e.g., `ssl: { rejectUnauthorized: false }` if needed by your client library).

3) Access the app
```
http://localhost:3000
```

Stop with Ctrl+C and remove containers if needed:
```
docker compose -f docker-compose.dev.yml down
```

### Production with Neon Cloud
In production, connect directly to your Neon Cloud database. No Neon Local container is used.

1) Copy and fill your environment
```
cp .env.production.example .env.production
# Set DATABASE_URL to your Neon Cloud URL, e.g.
# postgres://user:password@your-project-name.region.neon.tech/dbname?sslmode=require
```

2) Start the app
```
docker compose -f docker-compose.prod.yml up --build -d
```

This starts only the `app` service. Ensure your production infra handles TLS termination and secrets management appropriately. For orchestration (e.g., ECS, Kubernetes), use the same Dockerfile and inject environment variables via your platform’s secret store.

### Switching environments
- Development Compose reads from `.env.development` and sets `DATABASE_URL` to Neon Local by default.
- Production Compose reads from `.env.production` and uses the Neon Cloud `DATABASE_URL` you provide.

Environment precedence can be overridden by passing variables inline:
```
DATABASE_URL=postgres://... docker compose -f docker-compose.prod.yml up -d
```

## API
Base path may be `/auth` depending on how routes are mounted in your `src/index.js`/app setup. The route definitions are in `src/routes/auth.routes.js`.

All auth responses set an httpOnly cookie named `token` on success. For security, the token is not returned in the JSON body.

### Register
POST `/auth/register`
Request body:
```
{
  "name": "Alice",
  "email": "alice@example.com",
  "password": "secret123",
  "role": "user"
}
```
Response 201:
```
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "name": "Alice",
    "email": "alice@example.com",
    "role": "user",
    "createdAt": "2025-09-23T00:00:00.000Z"
  }
}
```
Sets cookie: `token` (httpOnly, sameSite=strict, secure in production).

Errors:
- 400 validation error (Zod)
- 409 user already exists

### Login
POST `/auth/login`
Request body:
```
{
  "email": "alice@example.com",
  "password": "secret123"
}
```
Response 200:
```
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "name": "Alice",
    "email": "alice@example.com",
    "role": "user",
    "createdAt": "2025-09-23T00:00:00.000Z"
  }
}
```
Sets cookie: `token`.

Errors:
- 400 validation error (Zod)
- 401 invalid credentials

### Logout
POST `/auth/logout`
Response 200:
```
{ "message": "Logged out successfully" }
```
Clears cookie: `token`.

## Implementation Notes
- `src/controllers/auth.controller.js` contains controllers for Register, Login, Logout.
- `src/services/auth.service.js` contains:
  - `createUser()` with conflict check and password hashing
  - `findUserByEmail()` and `authenticateUser()` for login
- `src/validations/auth.validation.js` defines `registerSchema` and `loginSchema` (Zod).
- `src/utils/cookies.js` centralizes cookie options (httpOnly, sameSite, maxAge, secure in production).
- JWTs are created by `src/utils/jwt.js` and stored in httpOnly cookies for better security.

## Scripts
- `npm run dev` — start server with watch
- `npm run lint` — run ESLint
- `npm run format` — run Prettier write
- `npm run db:generate` — generate migrations (drizzle-kit)
- `npm run db:migrate` — run migrations (drizzle-kit)
- `npm run db:studio` — open Drizzle Studio

## Security
- httpOnly cookies prevent JavaScript access to tokens
- `sameSite: strict` reduces CSRF risk (consider CSRF tokens for state-changing requests)
- `secure: true` in production requires HTTPS
- Store strong `JWT_SECRET` and rotate periodically

## Troubleshooting
- ReferenceError about variables in controller catch blocks usually indicates trying to access try-scoped variables in catch; return generic info or pass data explicitly.
- Ensure `DATABASE_URL` is correct and reachable; for Neon, enable IP allow rules if needed.
- If cookie isn’t set in development, check domain/port and that you’re not mixing HTTPS/HTTP.
- When using Neon Local, confirm your env has `NEON_API_KEY` and `NEON_PROJECT_ID`, and that your app uses the compose service hostname `neon-local` in `DATABASE_URL`.

## License
ISC
