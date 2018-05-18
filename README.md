# Cobbler

## Build image

    docker build -t local/cobbler .

## Runtime Env

* HOST_IP_ADDR: Physical host IP address (for cobbler_api): MANDATORY
* HOST_HTTP_PORT: Physical host IP port connected to HTTP port on container (for cobbler_api) (default is 80)
* DEFAULT_ROOT_PASSWD: Default root password (default is cobbler): Optional
* COBBLER_WEB_USER: Cobbler user for cobbler_web digest (default is cobbler): Optional
* COBBLER_WEB_PASSWD: Cobbler password for cobbler_web digest (default is cobbler): Optional
* COBBLER_WEB_REALM: Cobbler realm for cobbler_web digest (default is Cobbler): Optional
* COBBLER_LANG: lang to use (default is fr_FR): Optional
* COBBLER_KEYBOARD keyboard to use (default is fr-latin-9): Optional
* COBBLER_TZ: Timezone to use (default is Europe/Paris): Optional

## Runtime

On host, we mount iso in the directory /mnt/centos (which will be shared with container).

    sudo mkdir /mnt/centos

    sudo mount -o ro /path/to/isos/CentOS-7-x86_64-DVD-1804.iso /mnt/centos
    
    docker volume create cobbler_www
    docker volume create cobbler_tftp
    docker volume create cobbler_config
    docker volume create cobbler_backup
    docker volume create cobbler_run
    
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
               local/cobbler:latest

### Import distros

#### Add memtest target

    cobbler image add --name=memtest86+ --file=/boot/memtest86+-5.01 --image-type=direct

#### Add centos 7 distro (x86_64)

    cobbler import --path=/mnt --name=CentOS-7-x86_64

### Additionnal centos 7 profiles (same distro as profile CentOS-7-x86_64)

CentOS 7 Desktop

    cobbler profile add --name=CentOS-7-x86_64-Desktop --distro=CentOS-7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/sample_end.ks --virt-file-size=12 --virt-ram=2048
    
    cobbler profile edit --name CentOS-7-x86_64-Desktop --ksmeta="type=desktop"

## License

All files are licensed under the GPLv3 (See COPYING file)
