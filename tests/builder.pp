class { 'koji::builder':
    topdir    => '/mnt/koji',
    server    => 'http://kojihub.example.com/kojihub',
    topurl    => 'http://kojiweb.example.com/kojifiles/',
    smtphost  => 'mail.example.com',
    from_addr => 'Koji Build System <buildsys@example.com>',
    cert      => '/etc/kojid/kojibuilder01.pem',
    ca        => '/etc/kojid/koji_ca_cert.crt',
    serverca  => '/etc/kojid/koji_ca_cert.crt'
}

