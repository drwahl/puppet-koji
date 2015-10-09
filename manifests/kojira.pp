# http://fedoraproject.org/wiki/Koji/ServerHowTo#Kojira_-_Yum_repository_creation_and_maintenance
# kojira creates and maintains yum repos
#
# a few notes:
# - Kojira needs r/w access to koji mount
# - Only one kojira instance should be running at any given time
# - Kojira should not be run on the builders as builders only need r/o access to koji mount
# - Kojira needs to be restarted when new tags

class koji::kojira (
    $kojimount      = '/mnt/koji',
    $kojihub_url    = 'http://kojihub.example.com/kojihub',
    $logfile        = '/var/log/kojira.log',
    $with_src       = 'no',
    $cert           = '/etc/kojira/client.crt',
    $ca             = '/etc/kojira/clientca.crt',
    $serverca       = '/etc/kojira/serverca.crt',
    $force_lock     = 'Y',
    $kojira_debug   = 'N',
    $kojira_verbose = 'Y',
    $runas          = 'root'
) {

    include ::koji::hub

    service { 'kojira':
        ensure  => running,
        enable  => true,
        require => Package['koji-utils']
    }

    file { $cert :
        ensure => present,
        source => 'puppet:///modules/koji/pki/kojira.pem',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['kojira']
    }

    file { $ca :
        ensure => present,
        source => 'puppet:///modules/koji/pki/koji_ca_cert.crt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['kojira']
    }

    file { $serverca :
        ensure => present,
        source => 'puppet:///modules/koji/pki/koji_ca_cert.crt',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['kojira']
    }

    file { '/etc/kojira/kojira.conf':
        ensure  => present,
        content => template('koji/kojira/kojira.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['kojira'],
        require => Package['koji-utils']
    }

    file { '/etc/sysconfig/kojira':
        ensure  => present,
        content => template('koji/kojira/kojira_sysconfig.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['kojira'],
        require => Package['koji-utils']
    }

}
