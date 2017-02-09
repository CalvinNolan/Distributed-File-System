# Lock Service

The locking service provides exclusive user write access to specific files for users and for the directory service when managing reads and writes. This service simply holds a semaphore for each file that is it told to lock. The locking service provides the `/lock`, `/unlock`, `/list` and `/isvalid` endpoints for users and other services to use to fully implement it's features throughout the system.

The `/lock` and `/unlock` endpoints simply create and delete the semaphores on a specific file. The `/list` endpoint tells a user of all the locks they currently own. The `/isvalid` endpoint is used on every attempt to write to a file. For this endpoint the service simply checks if a lock exists for the file that the user want to write to, if so then the token passed through must be the valid token currently locking that file. If there is no lock for the file, any lock passed through will be ignored and any user with access to the file will be validated. Providing lock tokens to the users allows users to share these tokens to anyone they wish, meaning they can hold exclusive access or provide specific group access to whom they chose.

The lock tokens, similar to the authentication tokens, are 64 bit url encoded strings. These tokens are provided to the user and are expected to be provided as a parameter for any requests to write to locked files.

By providing this service, users can be sure that no updates to a file will be overwritten or erased by others. With more time developing the lock service, some extremely useful extra functionality could be providing a log of locks or authenticated writes for anyone with file access to see, this would essentially provide a historical view of the state of the file.

<b>Note: </b>All server logic exists in `web/controllers/lock_controller.ex`, data modeling lives in `web/models/lock.ex`, routing in `web/router.ex` and response formatting in `web/views/lock_view.ex`.

# Installation
Install dependencies with `mix deps.get`

Create and migrate your database with `mix ecto.create && mix ecto.migrate`
 
Install Node.js dependencies with `npm install`

Start Phoenix endpoint with `mix phoenix.server`

The registry service will now be running on port 3050 of your machine.
