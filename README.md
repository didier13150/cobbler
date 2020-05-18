[![cobbler logo](https://cobbler.github.io/images/logo-brand.png)](http://cobbler.github.io/ "cobbler")

## Runtime Env

| Name                   | Presence      | Default value | Comment                                                   |
| :--------------------- | :-----------: | :-----------: | :-------------------------------------------------------- |
|  `HOST_IP_ADDR`        | __MANDATORY__ |               | Physical host IP address (usefull for cobbler_api)        |
|  `HOST_HTTP_PORT`      | Optional      | 80            | Physical host IP port connected to HTTP port on container |
|  `DEFAULT_ROOT_PASSWD` | Optional      | cobbler       | Default root password                                     |
|  `COBBLER_WEB_USER`    | Optional      | cobbler       | Cobbler user for cobbler_web digest                       |
|  `COBBLER_WEB_PASSWD`  | Optional      | cobbler       | Cobbler password for cobbler_web digest                   |
|  `COBBLER_WEB_REALM`   | Optional      | Cobbler       | Cobbler realm for cobbler_web digest                      |
|  `COBBLER_LANG`        | Optional      | fr_FR         | Lang to setup in target                                   |
|  `COBBLER_KEYBOARD`    | Optional      | fr-latin-9    | Keyboard to setup in target                               |
|  `COBBLER_TZ`          | Optional      | Europe/Paris  | Timezone to setup in target                               |

## Setup before runtime

On host, we create a mount point for the iso file

    sudo mkdir /mnt/centos
    
Always on host, we mount iso in the mount point /mnt/centos (which will be shared with container).

    sudo mount -o ro /path/to/isos/CentOS-7-x86_64-DVD-1804.iso /mnt/centos

We create our docker volumes. The last is not mandatory if host kernel is upper or equal to 4.7

    docker volume create cobbler_www
    docker volume create cobbler_tftp
    docker volume create cobbler_config
    docker volume create cobbler_backup
    docker volume create cobbler_run
    
## Start the container

Default value for HOST_HTTP_PORT is 80, but in this example we use the 60080 port.

    docker run -d \
               -v cobbler_www:/var/www/cobbler:Z \
               -v cobbler_tftp:/var/lib/tftp:Z \
               -v cobbler_config:/var/lib/cobbler/config:Z \
               -v cobbler_backup:/var/lib/cobbler/backup:Z \
               -v cobbler_run:/var/run/supervisor:Z \
               -v /mnt/centos:/mnt:Z \
               -e DEFAULT_ROOT_PASSWD=cobbler \
               -e HOST_IP_ADDR=$(hostname --ip-address | awk '{print $1}') \
               -e HOST_HTTP_PORT=60080 \
               -e COBBLER_WEB_USER=cobbler \
               -e COBBLER_WEB_PASSWD=cobbler \
               -e COBBLER_WEB_REALM=Cobbler \
               -e COBBLER_LANG=fr_FR \
               -e COBBLER_KEYBOARD=fr-latin9 \
               -e COBBLER_TZ=Europe/Paris \
               -p 69:69/udp \
               -p 60080:80 \
               -p 60443:443 \
               -p 25151:25151 \
               --name cobbler \
               tartarefr/docker-cobbler:latest

### Import distros

#### Add memtest target

    cobbler image add --name=memtest86+ --file=/boot/memtest86+-5.01 --image-type=direct

#### Add centos 7 distro (x86_64)

    cobbler import --path=/mnt --name=CentOS-7-x86_64

### Additionnal centos 7 profiles (same distro as profile CentOS-7-x86_64)

CentOS 7 Desktop

    cobbler profile add --name=CentOS-7-x86_64-Desktop --distro=CentOS-7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/sample_end.ks --virt-file-size=12 --virt-ram=2048
    
    cobbler profile edit --name CentOS-7-x86_64-Desktop --ksmeta="type=desktop"

## Rebuild the image on your own

    docker build -t local/docker-cobbler .
    
And use replace `tartarefr/docker-cobbler` by `local/docker-cobbler`

## License

All files are licensed under the GPLv3 (See COPYING file)

## Known issues

* Iso file must be mounted on host before starting container. Unfortunatly iso cannot be replaced (unmounted-mounted in the same place) when container is created.
* With SELinux set to enforcing, container can read iso mounted directory content only with `--privileged` option
* Ports 69 and 25151 cannot be changed on host
