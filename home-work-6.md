# Homework 6

Homework 6 adds JWT authentication and comments owned by authenticated users.

## Authentication

`POST /api/auth/login` now returns `200 OK` with an access token:

```json
{
  "accessToken": "<jwt>"
}
```

The token contains the authenticated user's ID, is signed with `JWT_SECRET`,
and expires after one hour. Protected requests use the following header:

```text
Authorization: Bearer <accessToken>
```

`GET /api/auth/me` validates the bearer token and returns:

```json
{
  "email": "user@example.com",
  "login": "userLogin",
  "userId": "..."
}
```

Invalid, expired, malformed, or deleted-user tokens return `401 Unauthorized`.
The Express request type is augmented in `src/types/index.d.ts` with
`userId: string | null`.

## Comments

The following endpoints are available:

- `POST /api/posts/:postId/comments` — create a comment as the authenticated
  user.
- `GET /api/posts/:postId/comments` — return paginated comments for a post.
- `GET /api/comments/:id` — return one comment.
- `PUT /api/comments/:commentId` — update an owned comment.
- `DELETE /api/comments/:commentId` — delete an owned comment.

Comment content must contain between 20 and 300 characters. A comment response
has this shape:

```json
{
  "id": "...",
  "content": "A comment with valid content",
  "commentatorInfo": {
    "userId": "...",
    "userLogin": "userLogin"
  },
  "createdAt": "2026-11-10T10:00:00.000Z"
}
```

Creating, updating, and deleting comments requires bearer authentication. An
authenticated user trying to change another user's comment receives
`403 Forbidden`. Missing comments and posts return `404 Not Found`.

The command side stores comment documents and returns generated IDs. The query
repository maps stored comments to `CommentViewModel` objects and builds
paginated responses.

## Configuration

Set a long random JWT signing secret in the environment:

```env
JWT_SECRET=replace-with-a-long-random-jwt-secret
```

The secret must not be committed to Git or exposed to clients.
