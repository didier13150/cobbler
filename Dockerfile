FROM rockylinux/rockylinux

LABEL MAINTAINER "Didier FABERT <didier.fabert@gmail.com>"

# RPM REPOs
RUN dnf install -y \
    epel-release \
    ; [ $? -eq 0 ] || exit 1 \
    ; dnf clean all \
    ; rm -rf /var/cache/dnf

RUN dnf update -y \
    ; [ $? -eq 0 ] || exit 1 \
    ; dnf clean all \
    ; rm -rf /var/cache/dnf

RUN dnf module enable -y cobbler

RUN dnf install -y \
    cobbler \
    cobbler-web \
    pykickstart \
    debmirror \
    curl wget \
    rsync \
    supervisor \
    net-tools \
    memtest86+ \
    which \
    mod_ssl \
    jq \
    less \
    createrepo_c \
    python3-librepo python3-schema \
    syslinux \
    grub2-efi-x64-modules \
    tree vim-enhanced \
    ; [ $? -eq 0 ] || exit 1 \
    ; dnf clean all \
    ; rm -rf /var/cache/dnf

# Copy supervisor conf
COPY supervisord/supervisord.conf /etc/supervisord.conf
COPY supervisord/cobblerd.ini /etc/supervisord.d/cobblerd.ini
COPY supervisord/tftpd.ini /etc/supervisord.d/tftpd.ini
COPY supervisord/httpd.ini /etc/supervisord.d/httpd.ini
COPY supervisord/rsyncd.ini /etc/supervisord.d/rsyncd.ini

# Copy personnal snippets
COPY snippets/add_repos /var/lib/cobbler/snippets/add_repos
COPY snippets/configure_X /var/lib/cobbler/snippets/configure_X
COPY snippets/enable_X /var/lib/cobbler/snippets/enable_X
COPY snippets/partition_config /var/lib/cobbler/snippets/partition_config
COPY snippets/rkhunter /var/lib/cobbler/snippets/rkhunter
COPY snippets/systemd_persistant_journal /var/lib/cobbler/snippets/systemd_persistant_journal
COPY snippets/rpm_update /var/lib/cobbler/snippets/rpm_update
COPY snippets/func_install_if_enabled /var/lib/cobbler/snippets/func_install_if_enabled

# Copy personnal templates


# Use personnal snippets
RUN for kickstart in sample sample_legacy ; \
    do \
        additional_post_snippets="" ; \
        for snippet in \
                        add_repos \
                        rkhunter \
                        systemd_persistant_journal \
                        rpm_update \
                        enable_X ; \
        do \
          additional_post_snippets="${additional_post_snippets}\n\$SNIPPET('${snippet}')" ; \
        done ; \
        sed -i \
           -e "/post_anamon/ s/$/${additional_post_snippets}/" \
           -e "/^autopart/ s/^.*$/\$SNIPPET('partition_config')/" \
           -e "/^skipx/ s/^.*$/\$SNIPPET('configure_X')/" \
           -e "/^%packages/ s/$/\n\$SNIPPET('func_install_if_enabled')/" \
           -e "/^selinux/ s/disabled/enabled/" \
       /var/lib/cobbler/templates/${kickstart}.ks ; \
    done

RUN sed -i -e '/^@dists/ s/^/# /' \
           -e '/^@arches/ s/^/# /' \
           /etc/debmirror.conf
           
RUN sed -i \
    -e '/manage_rsync/ s/0/1/' \
    /etc/cobbler/settings

RUN sed -i \
    -e '/^\[cobbler-distros\]/i log file = /dev/stdout\ntransfer logging = yes\n' \
    /etc/cobbler/rsync.template

COPY first-sync.sh /usr/local/bin/first-sync.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh /usr/local/bin/first-sync.sh

EXPOSE 69 80 443 25151

VOLUME [ "/var/www/cobbler", "/var/lib/tftpboot", "/var/lib/cobbler/config", "/var/lib/cobbler/collections", "/var/lib/cobbler/backup", "/var/log/cobbler", "/mnt" ]

ENTRYPOINT /entrypoint.sh
