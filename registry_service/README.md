# Registry Service

The registry service provide a static service that documents and manages the routing and addresses of each other service in the system. This allows for organisation and recitifaction of any core service that fails.

The service provides two endpoints, `/register` and `/service` for registering new services and getting the host name for existing services respectively. The main use of this is to allow other services to dynamically learn where the other services live instead of relying on a static address. This also allows for the registry service to constantly check the state of each service by polling an `/alive` endpoint to know when to rectify a service and where to route requests as a backup if a service is dead. The only requirement is that the registry service lives on a static address that all other services can confidently query knowing that it won't change. The registry service stores the name and hostname for each registered service without allowing duplicates.

Another concern is that "Who watches the watchmen?", i.e. nothing watches the registry service in the case that is dies, causing a huge fault for all services in the system. A work around this would be to distribute the work of the service accross multiple registry services (similar to how the file services work) and give them the power to rectify a failed service.

Even though this service provides a simple and powerful way to ensure service uptime for users, the services don't currently utilise the ability to get a dynamically changing hostname through the `/service` enpoint. At the moment each service only registers itself on startup through `/register`. If more time was dedicated on the project, a big priority would be to implement actually rectifying of services through the registry service and ensuring each other service gets the correctly registered host for another service through this registry service before trying to query it.

<b>Note: </b>All server logic exists in the `web/controllers/registry_controller.ex`, data modeling lives in `web/models/service.ex`, routing in `web/router.ex` and response formatting in `web/views/registry_view.ex`.

# Installation
Install dependencies with `mix deps.get`

Create and migrate your database with `mix ecto.create && mix ecto.migrate`
 
Install Node.js dependencies with `npm install`

Start Phoenix endpoint with `mix phoenix.server`

The registry service will now be running on port 3000 of your machine.
