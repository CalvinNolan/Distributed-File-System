# Distributed File System

A Distributed File System compromising of many REST services. The core services are written in 
<a href=""http://elixir-lang.org">Elixir<a> with the <a href="http://www.phoenixframework.org">Phonenix Framework</a>.
The services are capable of existing on physically seperate machines while working together in a true distributed fashion.

The entire system provides a distributed file system that can be utilised through a web client. 
The web client uses user accounts and cookie based authentication. 
The features of the distributed file system include typical file storage, sharing and 
locking all through a full replicated and encrytped set of file servers.

# Services

The system is compromised of 6 services.
<ul>
  <li>Client Service</li>
  <li>Directory Service</li>
  <li>File Service</li>
  <li>Security Service</li>
  <li>Lock Service</li>
  <li>Registry Service</li>
</ul>

Each service's implementation exists in it's own folder in the repo with it's own readme explaining the design behind the service.