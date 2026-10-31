# Home work 4

## Goal

Add pagination and sorting for blogs and posts, blog name search, and endpoints
for posts that belong to a specific blog. Public routes use the universal
`/api` prefix instead of including a homework number.

## API changes

### Paginated lists

The following endpoints return paginated responses:

- `GET /api/blogs`
- `GET /api/posts`
- `GET /api/blogs/:blogId/posts`

Common query parameters:

| Parameter | Default | Description |
| --- | --- | --- |
| `pageNumber` | `1` | One-based page number |
| `pageSize` | `10` | Number of items per page, from 1 to 50 |
| `sortBy` | `createdAt` | Field used for sorting |
| `sortDirection` | `desc` | Sort direction: `asc` or `desc` |

Allowed `sortBy` values:

- blogs: `createdAt`, `name`, `websiteUrl`;
- posts: `createdAt`, `title`, `shortDescription`.

`GET /api/blogs` additionally accepts `searchNameTerm`. It performs a
case-insensitive literal substring search in the blog name.

Paginated response shape:

```json
{
  "pagesCount": 1,
  "page": 1,
  "pageSize": 10,
  "totalCount": 1,
  "items": []
}
```

### Blog-specific posts

- `GET /api/blogs/:blogId/posts` returns only posts that belong to the requested
  blog and responds with `404` when the blog does not exist.
- `POST /api/blogs/:blogId/posts` creates a post for the requested blog. The
  request body contains `title`, `shortDescription`, and `content`; the service
  resolves `blogId` and `blogName`. Basic Auth is required. The endpoint
  responds with `404` when the blog does not exist.

Existing CRUD endpoints remain available under `/api/blogs` and `/api/posts`.

## Architecture changes

The application follows the layered approach introduced in the lesson:

```text
Router -> Handler -> Service -> Command repository -> MongoDB
                 \-> Query repository -------------> MongoDB
```

- Services create domain objects and coordinate business operations.
- Command repositories modify data and perform reads required by command-side
  business rules.
- Query repositories implement filtering, sorting, and pagination for reads.
- A shared paginator maps MongoDB results to the API response model.
- Query validation supplies typed default values before the handler runs.

No database migration is required: homework 4 changes query behavior and route
composition, not the stored document shape.
