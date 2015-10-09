class { '::koji::dev':
  username => 'jdoe',
  server   => 'http://kojihub01.example.com/kojihub',
  weburl   => 'http://kojiweb01.example.com/koji',
  topurl   => 'http://kojiweb01.example.com/',
  cert     => '/etc/koji/user.pem',
  ca       => '/etc/koji/koji_ca.crt',
  serverca => '/etc/koji/koji_serverca.crt',
  caname   => 'koji'
}
