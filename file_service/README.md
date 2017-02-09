# File Service

The file service is a very simple service design to serve, store and update files. It's designed to be deployed alongside many other file services to together support and distribute the work of an entire file system. The simplicity of the file service is in part due to it's management from the directory service which watches and connects all the existing file services.

The file service provides the `/read`, `/write` and `/update` endpoints which provide the features you would expect. Each file service stores the files in a `files` directory while a reference to it's location is stored in the database. A decision was made to not store the files as binary large objects (BLOBS) in the database and instead store references to their location while saving copies locally. The main reason for this decision is to avoid the overhead in handling large amounts of binary when reading and writing them as a different format in a relational database. 

New files are taken in the form data format which is automatically handled by a built in Phoenix library known as Plug. Plug converts the requested file contents into a temporary file and provides the file location. A reference to the temporary file's infomation is stored in the database and then copied to create a hard copy on the file server. Upon a write access the hard copy's contents are returned as binary through Plug. 

When a user wishes to update a file, the only requirements enforced are that the newly updated file has the same name and content-type. This ensures the user is uploading the correct file to update.

Ontop of storing files as their primary place of storage, file services are used as a backup for other file services. The backup files are documented equally like all other files on the service but are handled differently by the directory service which holds seperate references for backup files compared to primary files.

On startup a file service registers itself with the directory service to let it know it's available for storage and backup.

If more time was dedicated to developing the file service, a different database that specialise in storing files could have been used to ensure stronger security and faster read and write times.

<b>Note: </b>All server logic exists in `web/controllers/file_controller.ex`, data modeling lives in `web/models/file.ex`, routing in `web/router.ex` and response formatting in `web/views/file_view.ex`.

# Installation
Install dependencies with `mix deps.get`

Create and migrate your database with `mix ecto.create && mix ecto.migrate`
 
Install Node.js dependencies with `npm install`

Start Phoenix endpoint with `PORT=303X mix phoenix.server` replacing `X` with a number of your choice. Ensure the input port number is not already in use by a pre-existing file service.

The registry service will now be running the specified port of your machine.
