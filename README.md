# docker-dspace

Docker container for [DSpace 5.1][3]

## Install dependencies

  - [Docker][2]

To install docker in Ubuntu 14.04 use the commands:

    $ sudo apt-get update
    $ sudo apt-get install docker.io

## Usage

To run container use the command below:

    $ docker run -d -p 8080:8080 quantumobject/docker-dspace

### Creating a administrator user

You need to run this command from the container to create the administrator user:

    $ docker exec -it container_id create-admin

And respond (yes) to clean the database and the other question relate to create administrator account.

## Accessing the DSpace applications:

After that check with your browser at addresses:

XMLUI
 - **http://host_ip:8080/xmlui/** 
 
JSPUI
 - **http://host_ip:8080/jspui/**
 
OAI
 - **http://host_ip:8080/oai/**

## More Info

More info about DSpace: [www.dspace.org][1]

[1]:http://www.dspace.org
[2]:https://www.docker.com
[3]:https://wiki.duraspace.org/display/DSPACE/DSpace+Release+5.1+Status
