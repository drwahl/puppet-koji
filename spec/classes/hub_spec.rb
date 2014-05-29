require 'spec_helper'

describe 'koji::hub', :type => :class do

    let (:params) { {
        :dbname               => 'koji',
        :dbuser               => 'koji',
        :dbhost               => 'db.example.com',
        :dbpass               => 'password',
        :kojidir              => '/mnt/koji',
        :authprincipal        => 'host/kojihub@EXAMPLE.COM',
        :authkeytab           => '/etc/koji.keytab',
        :proxyprincipals      => 'koji/kojiweb@EXAMPLE.COM',
        :hostprincipalformat  => 'compile/%s@EXAMPLE.COM',
        :dnusernamecomponent  => 'CN',
        :proxydn              => '/C=US/ST=Washington/L=Seattle/O=Example/OU=IT/CN=example/emailAddress=koji@example.com',
        :logincreateuser      => 1,
        :kojiweburl           => 'http://kojiweb.example.com/koji',
        :emaildomain          => 'example.com',
        :notifyonsuccess      => 'True',
        :disablenotifications => 'False',
        :enablemaven          => 'False',
        :enablewin            => 'False',
        :pluginpath           => '/usr/lib/koji-hub-plugins',
        :plugins              => 'echo',
        :kojidebug            => 'On',
        :kojitraceback        => 'normal',
        :serveroffline        => 'False',
        :offlinemessage       => 'temporary outage',
        :lockout              => 'False'
    } }
    #this is needed for the apache class. sigh...
    let (:facts) { {
        :operatingsystem        => 'CentOS',
        :operatingsystemrelease => '6',
        :osfamily               => 'RedHat',
        :fqdn                   => 'kojihub.example.com'
    }}
    #apache has a failing rspec-test
    #it { should contain_class('apache') }

    it { should contain_package('koji-hub').with_ensure('present') }
    it { should contain_package('koji').with_ensure('present') }
    it { should contain_package('koji-utils').with_ensure('present') }
    it { should contain_user('koji').with({
        'ensure'  => 'present',
        'comment' => 'Koji role account for Koji DB',
        'groups'  => 'postgres'
    }) }
    it { should contain_file('/var/lib/pgsql/data/pg_hba.conf').with({
        'ensure' => 'present',
        'owner'  => 'postgres',
        'group'  => 'postgres',
        'mode'   => '0600'
    }) }
    it { should contain_file("#{params[:kojidir]}/packages").with({
        'ensure' => 'directory',
        'owner'  => 'apache',
        'group'  => 'apache'
    }) }
    it { should contain_file("#{params[:kojidir]}/repos").with({
        'ensure' => 'directory',
        'owner'  => 'apache',
        'group'  => 'apache'
    }) }
    it { should contain_file("#{params[:kojidir]}/work").with({
        'ensure' => 'directory',
        'owner'  => 'apache',
        'group'  => 'apache'
    }) }
    it { should contain_file("#{params[:kojidir]}/scratch").with({
        'ensure' => 'directory',
        'owner'  => 'apache',
        'group'  => 'apache'
    }) }
    it { should contain_exec('create_koji_role_user').with({
        'user'    => 'postgres',
        'command' => 'createuser -DSR koji',
        'unless'  => 'psql -c "\du" | grep -q koji'
    }) }
    it { should contain_file('/etc/pki/koji').with({
        'ensure'  => 'directory',
        'recurse' => true,
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644'
    }) }
    it { should contain_file('/root/.koji').with({
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root'
    }) }
    ['/etc/koji-hub/hub.conf', '/etc/httpd/conf.d/kojihub.conf', '/root/.koji/config', '/root/.koji/koji_ca_cert.crt', '/root/.koji/root.pem', '/etc/koji-gc/koji-gc.conf'].each do |file|
        it { should contain_file("#{file}").with({
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0644'
        }) }
    end
    it 'should properly expand variables into hub.conf' do
        should contain_file('/etc/koji-hub/hub.conf').with_content(
            /^DBName = #{params[:dbname]}$/
        ).with_content(
            /^DBUser = #{params[:dbuser]}$/
        ).with_content(
            /^DBHost = #{params[:dbhost]}$/
        ).with_content(
            /^DBPass = #{params[:dbpass]}$/
        ).with_content(
            /^KojiDir = #{params[:kojidir]}$/
        ).with_content(
            /^AuthPrincipal = #{params[:authprincipal]}$/
        ).with_content(
            /^AuthKeytab = #{params[:authkeytab]}$/
        ).with_content(
            /^ProxyPrincipals = #{params[:proxyprincipals]}$/
        ).with_content(
            /^HostPrincipalFormat = #{params[:hostprincipalformat]}$/
        ).with_content(
            /^DNUsernameComponent = #{params[:dnusernamecomponent]}$/
        ).with_content(
            /^ProxyDNs = #{params[:proxydn]}$/
        ).with_content(
            /^LoginCreatesUser = #{params[:logincreateuser]}$/
        ).with_content(
            /^KojiWebURL = #{params[:kojiweburl]}$/
        ).with_content(
            /^EmailDomain = #{params[:emaildomain]}$/
        ).with_content(
            /^NotifyOnSuccess = #{params[:notifyonsuccess]}$/
        ).with_content(
            /^DisableNotifications = #{params[:disablenotifications]}$/
        ).with_content(
            /^EnableMaven = #{params[:enablemaven]}$/
        ).with_content(
            /^EnableWin = #{params[:enablewin]}$/
        ).with_content(
            /^PluginPath = #{params[:pluginpath]}$/
        ).with_content(
            /^Plugins = #{params[:plugins]}$/
        ).with_content(
            /^KojiDebug = #{params[:kojidebug]}$/
        ).with_content(
            /^KojiTraceback = #{params[:kojitraceback]}$/
        ).with_content(
            /^ServerOffline = #{params[:serveroffline]}$/
        ).with_content(
            /^OfflineMessage = #{params[:offlinemessage]}$/
        ).with_content(
            /^LockOut = #{params[:lockout]}$/
        )
    end
    it 'should properly expand variables in koji-gc.conf' do
        should contain_file('/etc/koji-gc/koji-gc.conf').with_content(
            /^server = https:\/\/#{facts[:fqdn]}\/kojihub$/
        ).with_content(
            /^weburl = http:\/\/#{facts[:fqdn]}\/koji$/
        )
    end
    it { should contain_file('/usr/local/bin/sign_unsigned.py').with({
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755'
    }) }
    it { should contain_file('/etc/pki/pkgsigner').with({
        'ensure'  => 'directory',
        'recurse' => true,
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0770'
    }) }
    it { should contain_cron('truncate_sessions_db').with({
        'ensure'  => 'present',
        'command' => 'DELETE FROM sessions WHERE update_time < now() - \'1 day\'::interval;',
        'user'    => 'koji',
        'minute'  => 0,
        'hour'    => 23,
        'weekday' => 5
    }) }
    it { should contain_cron('vacuum_db').with({
        'ensure'  => 'present',
        'command' => 'vacuumdb -fza > /dev/null',
        'user'    => 'postgres',
        'minute'  => 0,
        'hour'    => 0,
        'weekday' => 6
    }) }
    it { should contain_cron('koji_gc').with({
        'ensure'  => 'present',
        'command' => '/usr/sbin/koji-gc --purge --no-mail',
        'minute'  => 0,
        'hour'    => 10
    }) }
    it { should contain_cron('backup_koji_db').with({
        'ensure'  => 'present',
        'command' => 'pg_dump koji | gzip -c -9  > /var/lib/pgsql/backups/koji_db_`date +\\\\%d\\\\%m\\\\%Y`.sql.gz',
        'minute'  => 0,
        'hour'    => 5,
        'user'    => 'koji'
    }) }
    it { should contain_cron('prune_koji_db_backups').with({
        'ensure'  => 'present',
        'command' => 'find /var/lib/pgsql/backups -mtime 14 -exec rm -f {} \\\\;',
        'minute'  => 30,
        'hour'    => 0,
        'user'    => 'koji'
    }) }

end
