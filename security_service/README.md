# Security Service

The security service provides the core user authentication for all services to ensure actions are performed on the correct users and that data is only given to users with authorised access.

The main endpoints provided by this service are `/signup`, `/login`, `/logout` and `/authenticate`. The first three endpoints do exactly what they say while the `/authenticate` endpoint is used by every other service to validate an auth token for a specific user, essentially authenticating them.

Passwords are securely stored in the database in a hashed state and are never converted or handled in plaintext (and can't be!). Multiple sessions are not stored so a user can only be logged into one session at a time. With every log in a user is generated a unique authentication token which is a 64 bit url encoded string. This token is then set as a cookie in the response of the user log in which can be extracted and used in requests to other services that require authentication or can be used automatically as the cookie persists between requests. Used token are never deleted, only deprecated. This is to ensure duplicate tokens aren't created at any point in time.

As the scope of the overall system is small, user emails and account confirmation are not required when creating a new account. This means a user is free to log in immediately after signing up.

The `/authenticate` endpoint is the most used throughout the system. Every service that provides an endpoint directly to users will utilise `/authenticate` to ensure they have authorization to access what they're requesting. The endpoint takes in a username and an auth token, checks that this pair of data correctly authenticate someone according to the tokens the security service has reference to in it's database, and returns a boolean result with the user id of that user if the result was true.

The security service is a simple, secure and lightweight solution for such an important and heavily used part of the overall system.

<b>Note: </b>All server logic exists in `web/controllers/auth_controller.ex`, data modeling lives in `web/models/auth_token.ex` and `web/models/user.ex`, routing in `web/router.ex` and response formatting in `web/views/auth_view.ex`.

# Installation
Install dependencies with `mix deps.get`

Create and migrate your database with `mix ecto.create && mix ecto.migrate`
 
Install Node.js dependencies with `npm install`

Start Phoenix endpoint with `mix phoenix.server`

The registry service will now be running on port 3020 of your machine.
