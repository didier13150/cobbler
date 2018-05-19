[![cobbler logo](https://cobbler.github.io/images/logo-brand.png)](http://cobbler.github.io/ "cobbler")

## Runtime Env

| Name                     | MANDATORY     | Comment | Default value |
| :----------------------- | :------------ | :------------------------------------- | :------------- |
|  __HOST_IP_ADDR__        | __MANDATORY__ | Physical host IP address (usefull for cobbler_api) |
|  __HOST_HTTP_PORT__      | Optional      | Physical host IP port connected to HTTP port on container (usefull for cobbler_api) | 80 |
|  __DEFAULT_ROOT_PASSWD__ | Optional      | Default root password | cobbler |
|  __COBBLER_WEB_USER__    | Optional      | Cobbler user for cobbler_web digest | cobbler |
|  __COBBLER_WEB_PASSWD__  | Optional      |Cobbler password for cobbler_web digest | cobbler |
|  __COBBLER_WEB_REALM__   | Optional      | Cobbler realm for cobbler_web digest | Cobbler |
|  __COBBLER_LANG__        | Optional      | lang to setup in target |fr_FR |
|  __COBBLER_KEYBOARD__    | Optional      | keyboard to setup in target | fr-latin-9 |
|  __COBBLER_TZ__          | Optional      | Timezone to setup in target | Europe/Paris |

## Setup before runtime

On host, we create a mount point for the iso file

    sudo mkdir /mnt/centos
    
Always on host, we mount iso in the mount point /mnt/centos (which will be shared with container).

    sudo mount -o ro /path/to/isos/CentOS-7-x86_64-DVD-1804.iso /mnt/centos

We create our docker volumes. The last is optionnal if host kernel is upper or equal to 4.7

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

    docker build -t local/cobbler .

## License

All files are licensed under the GPLv3 (See COPYING file)

## Known issues

* Iso file must be mounted on host before starting container. Unfortunatly iso can not be replaced (unmounted-mounted in the same place) when container is created.
