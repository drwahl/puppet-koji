require 'spec_helper'

describe 'koji::builder', :type => :class do

    let (:params) {{
        :sleeptime             => 1,
        :maxjobs               => 1,
        :minspace              => 1,
        :topdir                => '/mnt/koji',
        :workdir               => '/tmp/koji',
        :mockdir               => '/var/lib/mock',
        :mockuser              => 'kojibuilder',
        :vendor                => 'Koji',
        :packager              => 'Koji',
        :distribution          => 'Koji',
        :mockhost              => 'koji-linux-gnu',
        :server                => 'http://kojihub.example.com/kojihub',
        :topurl                => 'http://kojiweb.example.com/kojifiles/',
        :allowed_scms          => 'git.example.org:/example',
        :smtphost              => 'smtp.exmple.com',
        :from_addr             => 'Koji Build System <buildsys@example.com>',
        :host_principal_format => 'compile/%s@EXAMPLE.COM',
        :keytab                => '/etc/kojid/kojid.keytab',
        :krbservice            => 'host',
        :cert                  => '/etc/kojid/client.crt',
        :ca                    => '/etc/kojid/clientca.crt',
        :serverca              => '/etc/kojid/serverca.crt',
        :user                  => 'koji'
    }}
    it { should contain_package('koji-builder').with_ensure('present') }
    it { should contain_service('kojid').with({
        'ensure' => 'running',
        'enable' => 'true',
    }) }
    it 'should deploy kojid.conf' do
        should contain_file('/etc/kojid/kojid.conf').with_ensure('present').with_content(
            /^sleeptime=#{params[:sleeptime]}$/
        ).with_content(
            /^maxjobs=#{params[:maxjobs]}$/
        ).with_content(
            /^minspace=#{params[:minspace]}$/
        ).with_content(
            /^topdir=#{params[:topdir]}$/
        ).with_content(
            /^workdir=#{params[:workdir]}$/
        ).with_content(
            /^mockdir=#{params[:mockdir]}$/
        ).with_content(
            /^mockuser=#{params[:mockuser]}$/
        ).with_content(
            /^vendor=#{params[:vendor]}$/
        ).with_content(
            /^packager=#{params[:packager]}$/
        ).with_content(
            /^distribution=#{params[:distribution]}$/
        ).with_content(
            /^mockhost=#{params[:mockhost]}$/
        ).with_content(
            /^server=#{params[:server]}$/
        ).with_content(
            /^topurl=#{params[:topurl]}$/
        ).with_content(
            /^allowed_scms=#{params[:allowed_scms]}$/
        ).with_content(
            /^smtphost=#{params[:smtphost]}$/
        ).with_content(
            /^from_addr=#{params[:from_addr]}$/
        ).with_content(
            /^user = #{params[:user]}$/
        ).with_content(
            /^host_principal_format = #{params[:host_principal_format]}$/
        ).with_content(
            /^keytab = #{params[:keytab]}$/
        ).with_content(
            /^krbservice = #{params[:krbservice]}$/
        ).with_content(
            /^cert = #{params[:cert]}$/
        ).with_content(
            /^ca = #{params[:ca]}$/
        ).with_content(
            /^serverca = #{params[:serverca]}$/
        )
    end
    it { should contain_file('/etc/kojid/koji_ca_cert.crt').with_ensure('present') }
    #TODO: need to figure out how to expand hostname correctly and test
    #that the pem file actually exists in the repo. probably need to
    #leverage fixtures here
    #should contain_file("/etc/kojid/#{:hostname}.pem").with_ensure('present')
    it { should contain_cron('clean_buildroots').with({
        'command' => 'find /var/lib/mock -type d -name root -mtime +1 -delete',
        'hour'    => 0,
        'minute'  => 0
    }) }

end
