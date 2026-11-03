# Home work 5

## Goal

Add user management, password hashing, and a basic credential-checking login
flow. All routes continue to use the universal `/api` prefix.

## Users API

The following endpoints require super-admin Basic Auth:

- `GET /api/users` returns a paginated user list;
- `POST /api/users` creates a user;
- `DELETE /api/users/:id` deletes a user.

User input fields:

| Field | Rules |
| --- | --- |
| `login` | 3-10 characters; letters, numbers, `_`, and `-`; unique |
| `password` | 6-20 characters |
| `email` | Valid email address; unique |

The API never returns `password` or `passwordHash`.

### Business uniqueness rules

Login and email uniqueness checks are implemented in the service/BLL layer,
not in validation middleware. A conflict produces exactly one error:

```json
{
  "errorsMessages": [
    {
      "field": "email",
      "message": "email should be unique"
    }
  ]
}
```

Login is checked before email when both fields conflict.

### Pagination and search

`GET /api/users` supports the common pagination and sorting parameters:

- `pageNumber`, default `1`;
- `pageSize`, default `10`, maximum `50`;
- `sortBy`: `createdAt`, `login`, or `email`;
- `sortDirection`: `asc` or `desc`, default `desc`.

It also supports `searchLoginTerm` and `searchEmailTerm`. Both searches are
case-insensitive literal substring searches. When both are supplied, users
matching either condition are returned (`$or`).

## Password hashing

Plain-text passwords are never persisted. User creation follows this flow:

```text
UserInputDto -> usersService -> bcrypt hash -> usersRepository -> MongoDB
```

The implementation uses bcrypt with 10 rounds. Only the resulting
`passwordHash` is stored.

## Login

`POST /api/auth/login` accepts:

```json
{
  "loginOrEmail": "user",
  "password": "password"
}
```

The auth service finds the user by exact login or email and verifies the plain
password against the stored bcrypt hash:

- valid credentials: `204 No Content`;
- invalid login, email, or password: `401 Unauthorized`;
- invalid request body: `400 Bad Request`.

This homework does not issue tokens or create sessions.
