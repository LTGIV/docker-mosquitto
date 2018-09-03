# Mosquitto with Authentication
>  [Mosquitto](https://mosquitto.org/) is a [message broker](https://en.wikipedia.org/wiki/Message_broker) that implements the MQTT protocol versions 3.1 and 3.1.1 (and in this Docker image, [WebSocket](https://en.wikipedia.org/wiki/WebSocket).) Mosquitto is lightweight and is suitable for use on all devices from low power single board computers to full servers.
>  
>  *[Mosquitto with Authentication](https://hub.docker.com/r/gotget/novnc/)* is a Docker image that bundles the [Mosquitto server](https://mosquitto.org/), popular authentication plugin, [mosquitto-auth-plug](https://github.com/jpmens/mosquitto-auth-plug), and [Libwebsockets](https://libwebsockets.org/) for WebSockets support, for ease-of-use.

## Download Docker image

### Pull from Docker Hub

#### Mosquitto compiled from source (latest and greatest)
```
docker pull ltgiv/docker-mosquitto:source
```

#### Mosquitto from [official PPA](https://launchpad.net/~mosquitto-dev/+archive/ubuntu/mosquitto-ppa) (sometimes slightly older version)
```
docker pull ltgiv/docker-mosquitto:ppa
```

### Build from GitHub
It's easy to build a local image directly from GitHub:

#### Clone repository and change to directory:
```
git clone https://github.com/LTGIV/docker-mosquitto.git \
&& \
cd ./docker-mosquitto \
;
```

##### Compiled from source (latest and greatest)
```
docker build \
    --tag ltgiv/docker-mosquitto:source \
    --file Dockerfile-source \
    . \
    ;
```

##### Installed from [official PPA](https://launchpad.net/~mosquitto-dev/+archive/ubuntu/mosquitto-ppa) (sometimes slightly older version)
```
docker build \
    --tag ltgiv/docker-mosquitto:ppa \
    --file Dockerfile-ppa \
    . \
    ;
```

## Examples
 - [Tying MQTT, WebSockets, and Nginx together with Docker](https://thad.getterman.org/2017/09/04/tying-mqtt-websockets-and-nginx-together-with-docker)

## Authors/Contributors
* [Louis T. Getterman IV](https://Thad.Getterman.org/about)
* Have an improvement? Your name goes here!

> Written with [StackEdit](https://stackedit.io/).
