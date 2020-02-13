# iSkyLIMS

Setup a *local development* environment for [iSkyLIMS](https://github.com/BU-ISCIII/iSkyLIMS).

With a few adjustments this can easily be adopted to a multiuser production ready solution, but I haven't had the time.

## Prerequisites

* Linux workstation
* Docker installed
* Docker compose installed
* Standard tools like git and vim

## Steps

From your command line:

```
$ cd
$ git clone git@github.com:iohenkies/iskylims_docker.git
$ cd iskylims
$ ls -al
```

In the `conf` folder, you can edit what you need. What you need to change always is:

* INSERTDJANGOPASS at `./conf/settings.py`
* INSERTROOTPASS and INSERTDJANGOPASS at `./docker-compose.yml`
* INSERTROOTPASS and INSERTDJANGOPASS at `./scripts/migrations`

Then, still from the `iskylims` folder:

```
$ sudo docker build -t iskylimsapp .
$ sudo docker-compose up -d
$ sudo docker exec -it iskylimsapp /srv/iSkyLIMS/migrations
$ sudo docker-compose restart
```

On you workstation navigate to http://localhost:8000 with your browser.

Be sure to run the migrations script only once.
