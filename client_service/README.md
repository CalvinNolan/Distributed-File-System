# Client Service

Examples of what the web client look like <a href="https://github.com/CalvinNolan/Distributed-File-System#screenshots">can be seen here</a>

The client service provides a modern and easy to use interface to interact with the distributed file system in the form of a website.
Unlike the other services throughout the system, the client service is written in Javascript using the <a href="http://redux.js.org">Redux framework</a> with <a href="https://facebook.github.io/react/">React components</a>.
The client service is a single page application which means there are no page reloads, all data is handled asynchronously through the use of AJAX requests to all the other services.
The client service utilises all of the features described in the other services to create a complete experience reading, writing, sharing and updating files to a secure, distributed file service.

Through the use of cookie based authentication, the client service automatically fetches an existing user session and logs them in everytime the webpage is newly loaded. 
The service provides the auth token for the user to use as they wish but it also automatically handles this information for any requests through the web client to the other services.
The web client similarly shows and handles any lock tokens that the user owns.

Despite the simple interface, the client service manages a huge amount of data per user behind the front-end to ensure all requests and interactions are handled correctly. 
The reducers are used to update this data while the actions invoke changes to the data (through the use of requests to other services).

<b>Note: </b>All request logic exists in `actions/file.js` and `actions/auth.js`, data modeling lives in `reducers/auth.js` and `reducers/file.js`. Since it is a single page application, there is currently no routing.
`server.js` is what serves the file up to users and begins the rendering of the application.

# Installation
Install Node.js dependencies with `npm install`

Start serving the web client with `node server.js`

The client service will now be running on port 3010 of your machine.
