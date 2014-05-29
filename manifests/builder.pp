# Koji builder class. The workhorse of koji. Each new builder requires the
# following to be run on the koji-hub:
# koji add-host kojibuilder1 i386 x86_64
# koji add-host-to-channel kojibuilder1 createrepo
#
# !!!! NOTE !!!!
# Koji creates a user account and machine account based on the name of the
# in the commands above. It also looks for that string in the ssl cert. Be
# sure that the name used to add (koji add-host) and the name used to generate
# the cert are identical. If they are not, you will need to clean up the
# postgres database, which sucks.
#
# This defaults to a "capacity" (load average) of 2. To increase this limit,
# use the following command (on the koji-hub, again):
# koji edit-host --capacity=16 kojibuilder1
#
# For more information, see:
# https://fedoraproject.org/wiki/Koji/ServerHowTo#Koji_Daemon_-_Builder

class koji::builder (
    $sleeptime             = undef,
    $maxjobs               = undef,
    $minspace              = undef,
    $topdir                = '/mnt/koji',
    $workdir               = undef,
    $mockdir               = undef,
    $mockuser              = undef,
    $vendor                = undef,
    $packager              = undef,
    $distribution          = undef,
    $mockhost              = undef,
    $server                = 'http://kojihub.example.com/kojihub',
    $topurl                = 'http://kojiweb.example.com/kojifiles/',
    $allowed_scms          = undef,
    $smtphost              = 'mail.example.com',
    $from_addr             = 'Koji Build System <buildsys@example.com>',
    $host_principal_format = undef,
    $keytab                = undef,
    $krbservice            = undef,
    $cert                  = undef,
    $ca                    = undef,
    $serverca              = undef,
    $user                  = undef
) {

    package { 'koji-builder':
        ensure => present
    }

    service { 'kojid':
        ensure  => running,
        enable  => true,
        require => [
            Package['koji-builder'],
            File['/etc/kojid/kojid.conf']
        ]
    }

    file { '/etc/kojid/kojid.conf':
        ensure  => present,
        content => template('koji/builder/kojid.conf.erb'),
        require => Package['koji-builder'],
        notify  => Service['kojid']
    }

    file { '/etc/kojid/koji_ca_cert.crt':
        ensure  => present,
        source  => 'puppet:///modules/koji/pki/koji_ca_cert.crt',
        require => Package['koji-builder'],
        notify  => Service['kojid']
    }

    file { "/etc/kojid/${::hostname}.pem":
        ensure  => present,
        source  => "puppet:///modules/koji/pki/${::hostname}.pem",
        require => Package['koji-builder'],
        notify  => Service['kojid']
    }

    cron { 'clean_buildroots':
        command => 'find /var/lib/mock -type d -name root -mtime +1 -delete',
        hour    => 0,
        minute  => 0
    }

}
