# crooner

Run Docker stacks with cron.

This requires a Swarm cluster to operate as you need to pass [Docker
stacks](https://docs.docker.com/engine/reference/commandline/stack/).

## Why is this useful ?

This solves the following problems :

* Not dependent on a host anymore :
  * No cron configuration is needed on the Docker host
  * The cron job being in the swarm means it will run as long as your cluster
    is alive
* You can access the swarm networks
* You can run a full stack with multiple containers

## How does it work ?

This will run a small docker image containing only crond (Alpine derived from
the [docker Docker image](https://hub.docker.com/_/docker/)).

Each entry in the crontab will deploy a docker stack. That is why your stacks
should be "one-shot" (group of) containers. Typically this is what you started
with `--rm` before. Think of backups for instance.

You will then be able to check the results of your applications with `docker
logs` or `docker service logs` if you're running at least Docker 17.03.

## Requirements

Docker Engine >= 1.13.0 and [Swarm mode](https://docs.docker.com/engine/swarm/) initiated.

:warning: This will NOT work with [Docker Swarm](https://docs.docker.com/swarm/) (there are no stacks).

## How do I use it ?

You have to declare entries in your crontab in the following manner :

```crontab
*   * * * * crooner run my-stack
*/2 * * * * crooner run my-other-stack
```

Then for each stack, you have to create a 
[compose file version 3](https://docs.docker.com/compose/compose-file/)
and give it the same name as in your crontab. In our example, you would have
`my-stack.yml` and `my-other-stack.yml`.

Your files should look like this :

```
.
├── crontab
└── stacks
    ├── my-other-stack.yml
    └── my-stack.yml
```

`stacks/my-stack.yml`

```yaml
version: '3'
services:
    start:
        image: hello-world
        deploy:
            restart_policy:
                condition: none
```

`stacks/my-other-stack.yml`

```yaml
version: '3'
services:
    start:
        image: hello-seattle
        deploy:
            restart_policy:
                condition: none
```

You should really set the restart policy to none. If you don't Docker, will
restart the containers just as they exit, which is probably not what you want
(backups and other one-shot images).

Then you can run crooner on one of your hosts like this :

```bash
docker run --volume /var/run/docker.sock:/var/run/docker.sock \
           --volume $(pwd)/crontab:/etc/crontab \
           --volume $(pwd)/stacks:/stacks \
           --env CROONER_VERBOSE=yes \
           crooner start
```

When you're done setting up, you should run crooner itself inside a stack. As
it is running the crond daemon, it must keep running. It should be obvious but
you should not run multiple replicas inside your cluster.

This should get you running :

```yaml
version: '3'
services:
    start:
        image: crooner
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
            - ./crontab:/etc/crontab
            - ./stacks:/stacks
        command: start
        environment:
            CROONER_VERBOSE: "yes"
```

## Changer the docker client version

Just edit the Dockerfile and change the FROM
