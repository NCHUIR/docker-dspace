# docker-dspace

Docker container for [DSpace 5.3](https://github.com/DSpace/DSpace/tree/dspace-5.3) (And should work for versions after 4.2, [cris](https://github.com/Cineca/DSpace/tree/dspace-cris-5.3.0))

"DSpace is the software of choice for academic, non-profit, and commercial organizations building open digital repositories."

## Install dependencies

  - [Docker](https://docker.com)
  - [Docker-compose](https://docs.docker.com/compose/)
 
## Installation

#### 1. Clone this repo

```
git clone https://github.com/NCHUIR/docker-dspace.git
```

#### 2. Prepare source code 

the `dspace-src` folder is to store customized dspace source code. If this folder is empty, building script will use source code from [Dspace 5.3 Cris](https://github.com/DSpace/DSpace/releases/download/dspace-5.3/dspace-5.3-src-release.tar.gz). To get source code ready to be customized, 

```
cd dspace-src
rm .gitkeep # to make this folder really empty, which git needs
git clone <some_dspace_repo_git_url> .
```

#### 3. Customize source code, change code in `dspace-src`

The content of `dspace-src` folder is ignored by this git repo, you can have anything changes in `dspace-src`

Only `dspace-src/.gitkeep` is tracked by this repo, but you can have a `.gitkeep` on your dspace source repo so `docker-dspace` repo is kept clean.

#### 4. Build dspace docker image

Edit settings dspace required in `install/conf/env.conf`

```
vim <this_repo>/install/conf/env.conf # or other editor of your favorite
```

Using docker-compose is recommanded (Postgresql container `db` will run automatically by docker-compose).

```
docker-compose build
```

Or use vanilla docker, but you have to configure db connection settings in `install/conf/env.conf` before build image. (especially `POSTGRES_HOST`, default value `db` is for docker-compose)

```
docker build -t dspace .
```

This will take a long time to build, including `mvn`, `ant` and many things. After that, you are ready to go!

> Maybe you need some command after installation, see below

## Usage

#### Run the server in production

Use docker-compose 

```
docker-compose up dspace
```

Use vanilla docker

```
docker run -p 80:8080 dspace
```

#### Enter container shell to use some commands (eg. creating an administrator)

> For vanilla docker, see `shell` service of `docker-compose.yml` to learn how to use

```
docker-compose run shell
```

Then you can use dspace (excutables in /dspace/bin is linked to /usr/local/bin) as command, for example, creating an administrator

```
dspace create-administrator
```

#### Access postgresql cli via pgcli

> For docker-compose only

```
docker-compose run pgcli
```

## Make some data folder linked with host

> These are For docker-compose only

First, you need to copy the data volume out to `data` folder of this repo, the folder is ignored by git of course:

```
docker-compose run prepare_with_data
```

You will have `log`, `webapps`, `config`, `handle_server` copied to `data`, you can edit them using host tools or `less +F` to watch logs.

#### Run server with data mounted

Use `with_data` service to run dspace with these folders mounted

```
docker-compose up with_data
```

#### Enter container shell with data mounted

With `with_data` up,

```
docker exec -it $(docker-compose ps -q with_data) bash
```

#### Rebuild! (For dev purpose)

If you make some changes to java code, you need to rebuild dspace, here is a way to avoid totally `fresh_install`

```
docker-compose run [--serivce-ports|-p 8080:8080] rebuild
```

This will do the following:

* `mvn package -P !dspace-lni,!dspace-sword,!dspace-swordv2,!dspace-xmlui`
  * `!dspace-lni,!dspace-sword,!dspace-swordv2,!dspace-xmlui` will prevent building these project which not usually changed
* `ant update`
* `dspace.run`
  * if the rebuild is success, the `rebuild` service will immediately start dspace server for test
  * if the production is running, you need to use option to publish `8080` to another port: `-p 8080:8080` 

After rebuild is done and test server is stopped, if you want your changes to be saved, do:

```
docker commit $(docker ps -lq) dockerdspace_with_data # or other image name format as <docker-compose project name>_<service>
```

Then you can run your new image:

```
docker-compose up with_data
```

> This is anti-pattern for docker... only for more speed on dev, so if your new code runs fine, `docker-compose build` again

## Accessing the DSpace applications:

After that check with your browser at addresses:

XMLUI
 - **http://host_ip/xmlui/** 
 
JSPUI
 - **http://host_ip/jspui/**
 
OAI
 - **http://host_ip/oai/**

> Ports are mapped to `80` from `8080` by docker

> You can change url-service mapping by editing `install/conf/tomcat.conf`

## More Info

About DSpace: [www.dspace.org](http://www.dspace.org) / [Dspace CRIS](https://wiki.duraspace.org/display/DSPACECRIS/DSpace-CRIS+Home)

This repo is forked from [quantumobject's docker-dspace](https://github.com/QuantumObject/docker-dspace), but massively changed

