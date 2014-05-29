require 'spec_helper'

describe 'koji::web', :type => :class do

    let (:params) {{
        :sitename     => 'koji',
        :kojitheme    => 'foobar',
        :kojihuburl   => 'http://kojihub.example.com/kojihub',
        :kojifilesurl => 'http://kojiweb.example.com/kojifiles',
        :webprincipal => 'koji/web@EXAMPLE.COM',
        :webkeytab    => '/etc/httpd.keytab',
        :webccache    => '/var/tmp/kojiweb.ccache',
        :webcert      => '/etc/kojiweb/kojiweb.crt',
        :clientca     => '/etc/kojiweb/clientca.crt',
        :kojihubca    => '/etc/kojiweb/kojihubca.crt',
        :logintimeout => 72,
        :secret       => 'CHANGE_ME',
        :libpath      => '/usr/share/koji-web/lib',
        :kojimount    => '/mnt/koji'
    }}

    #apache has a failing rspec-test
    #it { should contain_class('apache') }
    it { should contain_package('koji-web').with_ensure('present') }
    ['/etc/kojiweb/web.conf', '/etc/httpd/conf.d/kojiweb.conf'].each do |webconf|
        it { should contain_file("#{webconf}").with({
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0644'
        }) }
    end
    it 'should properly expand variables in web.conf' do
        should contain_file('/etc/kojiweb/web.conf').with_content(
            /^SiteName = #{params[:sitename]}$/
        ).with_content(
            /^KojiTheme = #{params[:kojitheme]}$/
        ).with_content(
            /^KojiHubURL = #{params[:kojihuburl]}$/
        ).with_content(
            /^KojiFilesURL = #{params[:kojifilesurl]}$/
        ).with_content(
            /^WebPrincipal = #{params[:webprincipal]}$/
        ).with_content(
            /^WebKeytab = #{params[:webkeytab]}$/
        ).with_content(
            /^WebCCache = #{params[:webccache]}$/
        ).with_content(
            /^WebCert = #{params[:webcert]}$/
        ).with_content(
            /^ClientCA = #{params[:clientca]}$/
        ).with_content(
            /^KojiHubCA = #{params[:kojihubca]}$/
        ).with_content(
            /^LoginTimeout = #{params[:logintimeout]}$/
        ).with_content(
            /^Secret = #{params[:secret]}$/
        ).with_content(
            /^LibPath = #{params[:libpath]}$/
        )
    end
    it { should contain_file('/etc/pki/koji').with({
        'ensure'  => 'directory',
        'recurse' => true,
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644'
    }) }

end 
