require 'spec_helper'

describe 'koji::dev', :type => :class do

    let (:params) { {
        :username => 'flast',
        :server   => 'http://kojihub01.example.com/kojihub',
        :weburl   => 'http://kojiweb01.example.com/koji',
        :topurl   => 'http://kojiweb01.example.com/',
        :cert     => '/etc/koji/user.pem',
        :ca       => '/etc/koji/koji_ca.crt',
        :serverca => '/etc/koji/koji_serverca.crt',
        :caname   => 'koji'
    } }
    it { should contain_package('koji').with_ensure('present') }
    it { should contain_file('/etc/koji').with({
            'ensure' => 'directory',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0644'
        }) }
    it 'should deploy koji.conf with proper variable expansion' do
        should contain_file('/etc/koji.conf').with({
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0644'
        }).with_content(
            /^server = #{params[:server]}$/
        ).with_content(
            /^weburl = #{params[:weburl]}$/
        ).with_content(
            /^topurl = #{params[:topurl]}$/
        ).with_content(
            /^cert = #{params[:cert]}$/
        ).with_content(
            /^ca = #{params[:ca]}$/
        ).with_content(
            /^serverca = #{params[:serverca]}$/
        )
    end
    it { should contain_file("#{params[:cert]}").with({
            'ensure' => 'present',
            'owner'  => "#{params[:username]}",
            'mode'   => '0644'
        }) }
    it { should contain_file("#{params[:serverca]}").with({
            'ensure' => 'present',
            'owner'  => "#{params[:username]}",
            'mode'   => '0644'
        }) }
    it { should contain_file("#{params[:ca]}").with({
            'ensure' => 'present',
            'owner'  => "#{params[:username]}",
            'mode'   => '0644'
        }) }
end
