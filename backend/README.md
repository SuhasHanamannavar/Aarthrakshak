# FinGuard Backend

> AI-powered personal finance manager with real-time fraud detection

## Auth Strategy

- Supabase handles all authentication (signup/login/session/refresh)
- Frontend sends Supabase JWT in `Authorization: Bearer <token>` header
- Spring Boot validates JWT signature using Supabase JWT secret
- User UUID (`sub` claim) is extracted and used as principal in all endpoints

## Setup

1. Copy `application.yml` and fill in Supabase credentials:
   - `SUPABASE_HOST` — your Supabase database host
   - `SUPABASE_DB_PASSWORD` — your database password
   - `SUPABASE_JWT_SECRET` — from Supabase Dashboard > Settings > API > JWT Secret
   - `SUPABASE_PROJECT_REF` — your project reference (for URL)
   - `SUPABASE_ANON_KEY` — your anon/public key
2. Run the application:
   ```bash
   mvn spring-boot:run
   ```

## Stack

- Spring Boot 3.x, JPA, Security, WebSocket
- Supabase (Auth + PostgreSQL)
- Python ML microservice (port 5000)
