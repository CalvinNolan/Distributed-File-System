# Directory Service

The directory service is the heart of the entire distributed file system. It is responsible for managing and indexing file storage while ensuring replication and backup is in place for every registered file service. The directory service also utilises the lock service and security service to expand it's feature set all while directly responding to the client service.

The directory service provides the `/read`, `/write`, `/update`, `/share` and `/all` endpoints for the client service to directly handle all the file system features while hiding the heavy use of the other services from the user. The `/register` and `/access` endpoints are provided for the file services to interact with the directory service to allow themselves to be managed and for the locking service to authenticate and file changes respectively.

The two main parts of the directory service are the file distribution and managing and then the file service replication and backup. The directory service keeps a reference to every registered file service and decides upon the load that each of these services endures. It also ensures that a copy of all the files are backed up in another file service and can re-backup a server or rectify one when a file service fails. The directory service manages all the filer services in a ring like manner. Each file server backups up another until they are all backing each other up in one complete and continuously connected way.

For the first part of managing the files, the directory service keeps a reference to every file stored on every file service alongside it's owner's id, it's real file id, which file service it is stored on and what file service it's backed up on. When a new file is written to the system, the deirectory service evaluates the file count of every registered file server and picks the one with the least load to store the new file. The directory service also replicates the new file onto it's newly chosen file server's backup server. When a user wishes to update a file, the lock status is checked with the provided lock token and the request successfully executes depending on the outocome of this. A read will pass the request onto the correct file server that holds the file in question and then pass on the response back to the user.

The second part of the directory service implements a very sophisticated replication service that will ensure the longevity and access of all user files even if multiple file servers fail and die. When a file server is detected to have died the directory service will call upon the failed file server's backup server to complete the request. The directory service then notes the failed file service and sends all the newly lost files into a replication list for them to be backed up once more onto another server. It also executes this request on all the servers that were backed up by the failed file server. The directory server then invalidates any references to that file server and either set's the new reference to be that of the backup server or if the failed server was a backup for another server, request for all those files to be replicated and the set their backup to nothing until the new replication is complete. 

A constant replication script is then run continuously in the background of the service once every 30 seconds. This script looks at all the files that have requested to be replicated, saves them to a new backup and then updates the references to them for use in their new file servers. This replication strategy ensures every file is accessible in the case of a failed file server and that each file will continue to be accessible with newly registered and failed servers. This thorough replication strategy creates a much more secure and reliable system without having to introduce overhead in the form of extra services. It also allows for a dynamic system that is flexible to scale and grow overtime while still being able to distribute and manage the load equally. 

<b>Note: </b>All server logic exists in `web/controllers/directory_controller.ex`, data modeling lives in `web/models/file.ex`, `web/models/replication.ex` and `web/models/server.ex`, routing in `web/router.ex`, response formatting in `web/views/directory_view.ex` and replication logic in `lib/background_replication.ex`.

# Installation
Install dependencies with `mix deps.get`

Create and migrate your database with `mix ecto.create && mix ecto.migrate`
 
Install Node.js dependencies with `npm install`

Start Phoenix endpoint with `mix phoenix.server`

The registry service will now be running on port 3040 of your machine.
