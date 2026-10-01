# nodejs-blog-platform

A blogging platform built during the Node.js course at IT Incubator.

## Local development

Copy `.env.example` to `.env`, adjust the values, and start the application with
MongoDB:

```bash
docker compose up --build
```

The API prefix is configured with `API_PATH`; it is not hard-coded to a specific
homework number. Docker Compose builds `MONGO_URL` from `MONGO_USER`,
`MONGO_PASSWORD`, and `DB_NAME`, then passes the ready connection string to the
application. The database port is intentionally not published to the host.

MongoDB creates the `blogs` and `posts` collections on first use. The application
uses native MongoDB `ObjectId` identifiers and maps them to string `id` values in
API responses. A migration runner should be introduced only when existing
persisted documents require a backfill or another data transformation.
