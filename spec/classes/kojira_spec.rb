require 'spec_helper'

describe 'koji::kojira', :type => :class do

    let (:params) { {
        :cert           => '/etc/kojira/client.crt',
        :ca             => '/etc/kojira/clientca.crt',
        :serverca       => '/etc/kojira/serverca.crt',
        :kojimount      => '/mnt/koji',
        :kojihub_url    => 'http://kojihub.example.com/kojihub',
        :logfile        => '/var/log/kojira.log',
        :with_src       => 'no',
        :force_lock     => 'Y',
        :kojira_debug   => 'N',
        :kojira_verbose => 'Y',
        :runas          => 'root'
    } }

    it { should contain_class('koji::hub') }
    it { should contain_service('kojira').with({
        'ensure' => 'running',
        'enable' => true,
    }) }
    it { should contain_file("#{params[:cert]}").with({
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644'
    }) }
    it { should contain_file("#{params[:ca]}").with({
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644'
    }) }
    it { should contain_file("#{params[:serverca]}").with({
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644'
    }) }
    ['/etc/kojira/kojira.conf', '/etc/sysconfig/kojira'].each do |conffile|
        it { should contain_file("#{conffile}").with({
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755'
        }) }
    end
    it 'should properly expand variables in kojira.conf' do
        should contain_file('/etc/kojira/kojira.conf').with_content(
            /^server=#{params[:kojihub_url]}$/
        ).with_content(
            /^topdir=#{params[:kojimount]}$/
        ).with_content(
            /^logfile=#{params[:logfile]}$/
        ).with_content(
            /^with_src=#{params[:with_src]}$/
        ).with_content(
            /^cert = #{params[:cert]}$/
        ).with_content(
            /^ca = #{params[:ca]}$/
        ).with_content(
            /^serverca = #{params[:serverca]}$/
        )
    end
    it 'should properly expand variables in /etc/sysconfig/kojira' do
        should contain_file('/etc/sysconfig/kojira').with_content(
            /^FORCE_LOCK=#{params[:force_lock]}$/
        ).with_content(
            /^KOJIRA_DEBUG=#{params[:kojira_debug]}$/
        ).with_content(
            /^KOJIRA_VERBOSE=#{params[:kojira_verbose]}$/
        ).with_content(
            /^RUNAS=#{params[:runas]}$/
        )
    end

end
