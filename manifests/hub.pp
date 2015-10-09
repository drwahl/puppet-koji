# manage the koji-hub function of koji. This class requires apache with mod_ssl
# mod_wsgi and mod_python as well as a postgres database
#
# Some postgres work needs to be manually done for this to work properly. The
# following needs to be run manually:
# root@localhost$ su - postgres
# postgres@localhost$ createuser koji
# Shall the new role be a superuser? (y/n) n
# Shall the new role be allowed to create databases? (y/n) n
# Shall the new role be allowed to create more new roles? (y/n) n
# postgres@localhost$ createdb -O koji koji
# postgres@localhost$ psql -c "alter user koji with encrypted password '$dbpass';"
# postgres@localhost$ logout
# root@localhost$ su - koji
# koji@localhost$ psql koji koji < /usr/share/doc/koji*/docs/schema.sql
# koji@localhost$ logout
# root@localhost$ service postgresql reload
# root@localhost$ su - koji
# koji@localhost$ psql
# koji=> insert into users (name, status, usertype) values ('root', 0, 0);
# koji=> select * from users;
### Use the output above to find the user ID number ###
# koji=> insert into user_perms (user_id, perm_id, creator_id) values (<user ID>, 1, <user ID>);
# koji=> \q
# koji@localhost$ logout
# root@localhost$ service postgresql restart
#
# For more information, see:
# https://fedoraproject.org/wiki/Koji/ServerHowTo#Koji_Hub
#
# To leverage external repos for mock environment builds, the following commands were used:
# user@localhost:~/tmp $ koji add-tag centos-6
# user@localhost:~/tmp $ koji add-tag --parent centos-6 --arches "x86_64" centos-6-build
# user@localhost:~/tmp $ koji add-external-repo -t centos-6-build centos-6-external-repo http://mirror.example.com/centos/6/os/\$arch/
# Created external repo 1
# Added external repo centos-6-external-repo to tag centos-6-build (priority 5)
# user@localhost:~/tmp $ koji add-target centos-6 centos-6-build centos-6
# user@localhost:~/tmp $ koji add-group centos-6-build build
# user@localhost:~/tmp $ koji add-group centos-6-build srpm-build
# user@localhost:~/tmp $ koji add-group-pkg centos-6-build build bash bzip2 centos-release coreutils cpio diffutils findutils gawk gcc gcc-c++ grep gzip make patch redhat-rpm-config sed shadow-utils tar unzip util-linux-ng which xz texinfo rpm-build
# user@localhost:~/tmp $ koji regen-repo centos-6-build
#
# After the regen-repo is completed, you should be able to successfully build packages.

class koji::hub (
    $dbname               = 'koji',
    $dbuser               = 'koji',
    $dbhost               = undef,
    $dbpass               = undef,
    $kojidir              = '/mnt/koji',
    $authprincipal        = undef,
    $authkeytab           = undef,
    $proxyprincipals      = undef,
    $hostprincipalformat  = undef,
    $dnusernamecomponent  = 'CN',
    $proxydn              = '/C=US/ST=Washington/L=Seattle/O=Example/OU=Foo/CN=bar/emailAddress=foo@example.com',
    $logincreateuser      = undef,
    $kojiweburl           = undef,
    $emaildomain          = 'example.com',
    $notifyonsuccess      = true,
    $disablenotifications = undef,
    $enablemaven          = undef,
    $enablewin            = undef,
    $pluginpath           = undef,
    $plugins              = undef,
    $kojidebug            = undef,
    $kojitraceback        = undef,
    $serveroffline        = undef,
    $offlinemessage       = undef,
    $lockout              = undef
) {

  #include apache

    package { 'koji-hub':
        ensure => present
    }

    package { 'koji':
        ensure => present
    }

    package { 'koji-utils':
        ensure => present
    }

    #TODO: reconsider this user creation. service accounts should be created
    #by the RPMs that install the software.
    user { 'koji':
        ensure     => present,
        comment    => 'Koji role account for Koji DB',
        managehome => true,
        groups     => 'postgres'
    }

    #TODO: ugly hack for lack of control over posgres. this *needs* to be
    #addressed.
    file { '/var/lib/pgsql/data/pg_hba.conf':
        ensure  => present,
        content => template('koji/postgres/pg_hba.conf.erb'),
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0600'
    }

    file { "${kojidir}/packages":
        ensure => directory,
        owner  => 'apache',
        group  => 'apache',
        mode   => undef,
    }

    file { "${kojidir}/repos":
        ensure => directory,
        owner  => 'apache',
        group  => 'apache',
        mode   => undef,
    }

    file { "${kojidir}/work":
        ensure => directory,
        owner  => 'apache',
        group  => 'apache',
        mode   => undef,
    }

    file { "${kojidir}/scratch":
        ensure => directory,
        owner  => 'apache',
        group  => 'apache',
        mode   => undef,
    }

    exec { 'create_koji_role_user':
        user    => 'postgres',
        command => 'createuser -DSR koji',
        unless  => 'psql -c "\du" | grep -q koji'
    }

    file { '/etc/pki/koji':
        ensure  => directory,
        recurse => true,
        source  => 'puppet:///modules/koji/pki',
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    }

    file { '/etc/koji-hub/hub.conf':
        ensure  => present,
        content => template('koji/hub/hub.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    }

    file { '/etc/httpd/conf.d/kojihub.conf':
        ensure  => present,
        content => template('koji/hub/kojihub_httpd.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['httpd']
    }

    file { '/root/.koji':
        ensure => directory,
        owner  => 'root',
        group  => 'root'
    }

    file { '/root/.koji/config':
        ensure  => present,
        content => template('koji/hub/root_config.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    }

    file { '/root/.koji/koji_ca_cert.crt':
        ensure => present,
        source => 'puppet:///modules/koji/pki/koji_ca_cert.crt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644'
    }

    file { '/root/.koji/root.pem':
        ensure => present,
        source => 'puppet:///modules/koji/pki/koji.pem',
        owner  => 'root',
        group  => 'root',
        mode   => '0644'
    }

    file { '/etc/koji-gc/koji-gc.conf':
        ensure  => present,
        content => template('koji/hub/koji-gc.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['koji-utils']
    }

    file { '/usr/local/bin/sign_unsigned.py':
        ensure  => present,
        content => template('koji/hub/sign_unsigned.py.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755'
    }

    file { '/etc/pki/pkgsigner':
        ensure  => directory,
        source  => 'puppet:///modules/koji/gnupg',
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0770'
    }

    # Weekly truncate of sessions table before vacuum
    cron { 'truncate_sessions_db':
        ensure  => present,
        command => 'DELETE FROM sessions WHERE update_time < now() - \'1 day\'::interval;',
        user    => 'koji',
        minute  => 0,
        hour    => 23,
        weekday => 5,
        require => User['koji']
    }

    # Do a full vacuum daily at midnight
    cron { 'vacuum_db':
        ensure  => present,
        command => 'vacuumdb -fza > /dev/null',
        user    => 'postgres',
        minute  => 0,
        hour    => 0,
        weekday => 6
    }

    # Daily pruning of old builds
    cron { 'koji_gc':
        ensure  => present,
        command => '/usr/sbin/koji-gc --purge --no-mail',
        minute  => 0,
        hour    => 10,
        require => [
            File['/etc/koji-gc/koji-gc.conf'],
            Package['koji-utils']
        ]
    }

    cron { 'backup_koji_db':
        ensure  => present,
        command => 'pg_dump koji | gzip -c -9  > /var/lib/pgsql/backups/koji_db_`date +\\%d\\%m\\%Y`.sql.gz',
        minute  => 0,
        hour    => 5,
        user    => 'koji',
        require => User['koji']
    }

    cron { 'prune_koji_db_backups':
        ensure  => present,
        command => 'find /var/lib/pgsql/backups -mtime 14 -exec rm -f {} \\;',
        minute  => 30,
        hour    => 0,
        user    => 'koji',
        require => User['koji']
    }

}
