[![cobbler logo](https://cobbler.github.io/images/logo-brand.png)](http://cobbler.github.io/ "cobbler")

## Runtime Env

| Name                     | Presence      | Default value                      | Comment                                                   |
| :---                     | :---          | :---                               | :---                                                      |
|  `HOST_IP_ADDR`          | __MANDATORY__ |                                    | Physical host IP address (usefull for cobbler_api)        |
|  `HOST_HTTP_PORT`        | Optional      | 80                                 | Physical host IP port connected to HTTP port on container |
|  `DEFAULT_ROOT_PASSWD`   | Optional      | cobbler                            | Default root password                                     |
|  `COBBLER_WEB_USER`      | Optional      | cobbler                            | Cobbler user for cobbler_web digest                       |
|  `COBBLER_WEB_PASSWD`    | Optional      | cobbler                            | Cobbler password for cobbler_web digest                   |
|  `COBBLER_WEB_REALM`     | Optional      | Cobbler                            | Cobbler realm for cobbler_web digest                      |
|  `COBBLER_LANG`          | Optional      | fr_FR                              | Lang to setup in target                                   |
|  `COBBLER_KEYBOARD`      | Optional      | fr-latin-9                         | Keyboard to setup in target                               |
|  `COBBLER_TZ`            | Optional      | Europe/Paris                       | Timezone to setup in target                               |
|  `COBBLER_WEB_CERT`      | Optional      | /etc/pki/tls/certs/localhost.crt   | Full path of apache ssl certificate                       |
|  `COBBLER_WEB_KEY`       | Optional      | /etc/pki/tls/private/localhost.key | Full path of apache ssl key                               |
|  `COBBLER_WEB_KEYSIZE`   | Optional      | 2048                               | Apache ssl key size (default is 2048): Optional           |
|  `COBBLER_CERT_COUNTRY`  | Optional      | FR                                 | Country in SSL certificate                                |
|  `COBBLER_CERT_STATE`    | Optional      | Occitanie                          | State in SSL certificate                                  |
|  `COBBLER_CERT_CITY`     | Optional      | Beaucaire                          | City in SSL certificate                                   |
|  `COBBLER_CERT_ORGNAME`  | Optional      | HOME                               | Organization Name in SSL certificate (O)                  |
|  `COBBLER_CERT_ORGUNIT`  | Optional      | SysAdmin                           | Organization Unit in SSL certificate (OU)                 |
|  `COBBLER_CERT_HOSTNAME` | Optional      | cobbler.tartarefr.eu               | Hostname in SSL certificate                               |
|  `COBBLER_CERT_EMAIL`    | Optional      | root@cobbler.tartarefr.eu          | Email in SSL certificate                                  |

## Setup before runtime
    
On host, we create a mount point for the iso file

``` 
sudo mkdir -p /mnt/distros/{centos-7,centos-8,almalinux,rocky}
``` 
    
Always on host, we mount iso on the /mnt/distros mount point (which will be shared with container).

```
sudo mount /home/docker/cobbler/CentOS-7-x86_64-DVD-2009.iso /mnt/distros/centos-7
sudo mount /home/docker/cobbler/CentOS-8.4.2105-x86_64-dvd1.iso /mnt/distros/centos-8
sudo mount /home/docker/cobbler/AlmaLinux-8.4-x86_64-dvd.iso /mnt/distros/almalinux
sudo mount /home/docker/cobbler/Rocky-8.4-x86_64-dvd1.iso /mnt/distros/rocky
```

We create our docker volumes.

``` 
docker volume create cobbler_www
docker volume create cobbler_tftpboot
docker volume create cobbler_config
docker volume create cobbler_collections
docker volume create cobbler_backup
docker volume create cobbler_logs
```
    
## Start the container

Default value for HOST_HTTP_PORT is 80, but in this example we use the 60080 port.

```
docker run -d \
           -v cobbler_www:/var/www/cobbler:Z \
           -v cobbler_tftp:/var/lib/tftp:Z \
           -v cobbler_config:/var/lib/cobbler/config:Z \
           -v cobbler_collections:/var/lib/cobbler/collections:Z \
           -v cobbler_backup:/var/lib/cobbler/backup:Z \
           -v cobbler_logs:/var/log/cobbler:Z \
           -v /mnt/distros:/mnt/distros:Z \
           -e DEFAULT_ROOT_PASSWD=cobbler \
           -e HOST_IP_ADDR=$(hostname --ip-address | awk '{print $1}') \
           -e HOST_HTTP_PORT=60080 \
           -e COBBLER_WEB_USER=cobbler \
           -e COBBLER_WEB_PASSWD=cobbler \
           -e COBBLER_WEB_REALM=Cobbler \
           -e COBBLER_LANG=fr_FR \
           -e COBBLER_KEYBOARD=fr-latin9 \
           -e COBBLER_TZ=Europe/Paris \
           -e COBBLER_WEB_CERT=/etc/pki/tls/certs/localhost.crt \
           -e COBBLER_WEB_KEY=/etc/pki/tls/private/localhost.key \
           -e COBBLER_WEB_KEYSIZE=2048 \
           -e COBBLER_CERT_COUNTRY=FR \
           -e COBBLER_CERT_STATE="Occitanie \
           -e COBBLER_CERT_CITY=Beaucaire \
           -e COBBLER_CERT_ORGNAME=HOME \
           -e COBBLER_CERT_ORGUNIT=SysAdmin \
           -e COBBLER_CERT_HOSTNAME=cobbler.tartarefr.eu \
           -e COBBLER_CERT_EMAIL=root@cobbler.tartarefr.eu \
           -p 69:69/udp \
           -p 60080:80 \
           -p 60443:443 \
           -p 25151:25151 \
           --name cobbler \
           tartarefr/docker-cobbler:latest
```

### Import distros

#### Add memtest target

```
cobbler image add --name=memtest --file=/boot/memtest86+-5.01 --image-type=direct
```
    
#### Add centos distros (x86_64)

* On host, we mount iso file in 

```
cobbler import --path=/mnt//distros/centos-7 --name=CentOS-7
cobbler import --path=/mnt/distros/centos-8 --name=CentOS-8
cobbler import --path=/mnt/distros/almalinux --name=AlmaLinux
cobbler import --path=/mnt/distros/rocky --name=Rocky
```

### Additionnal centos 7 profiles (same distro as profile CentOS-7-x86_64)

CentOS 7 Desktop

```
cobbler profile add --name=CentOS-7-x86_64-Desktop --distro=CentOS-7-x86_64 --virt-file-size=12 --virt-ram=2048

cobbler profile edit --name CentOS-7-x86_64-Desktop --autoinstall-meta="type=desktop"
```

## Rebuild the image on your own

```
docker build -t local/docker-cobbler .
```
    
And replace `tartarefr/docker-cobbler` by `local/docker-cobbler`

## License

All files are licensed under the GPLv3 (See COPYING file)
    
## Known issues

* Iso file must be mounted on host before starting container. Unfortunatly iso can not be replaced (unmounted-mounted in the same place) when container is already created/running.
