require 'spec_helper'

describe 'teleport' do
  # RSpec.configure do |c|
  #   c.default_facts = {
  #     architecture: 'x86_64',
  #     operatingsystem: 'CentOS',
  #     osfamily: 'RedHat',
  #     operatingsystemrelease: '7.1.1503',
  #     kernel: 'Linux',
  #     fqdn: 'test',
  #     ipaddress: '192.168.5.10'
  #   }
  # end

  #### Installation ####

  context 'when installing via URL by default' do
    let(:params) do
      { version: 'v2.4.0' }
    end

    it {
      is_expected.to contain_archive('/tmp/teleport.tar.gz') \
        .with(source: 'https://github.com/gravitational/teleport/releases/download/v2.4.0/teleport-v2.4.0-linux-amd64-bin.tar.gz')
    }
    it {
      is_expected.to contain_file('/usr/local/bin/tctl') \
        .with(ensure: 'link', target: '/opt/teleport-v2.4.0/teleport/tctl')
    }
    it {
      is_expected.to contain_file('/usr/local/share/teleport') \
        .with(ensure: 'link', target: '/opt/teleport-v2.4.0/teleport/app')
    }
  end

  context 'when installing a special version' do
    let(:params) do
      {
        version: 'v.0.2.0-beta.8',
      }
    end

    it {
      is_expected.to contain_archive('/tmp/teleport.tar.gz') \
        .with(source: 'https://github.com/gravitational/teleport/releases/download/v.0.2.0-beta.8/teleport-v.0.2.0-beta.8-linux-amd64-bin.tar.gz')
    }
  end

  context 'when specifying a different archive path' do
    let(:params) do
      {
        version: 'v0.1.0-alpha.7',
        archive_path: '/opt/teleport.tar.gz',
      }
    end

    it {
      is_expected.to contain_archive('/opt/teleport.tar.gz') \
        .with(source: 'https://github.com/gravitational/teleport/releases/download/v0.1.0-alpha.7/teleport-v0.1.0-alpha.7-linux-amd64-bin.tar.gz')
    }
  end

  context 'when specifying a different bin_dir' do
    let(:params) do
      {
        version: 'v2.4.0',
        bin_dir: '/usr/sbin',
      }
    end

    it { is_expected.to contain_file('/usr/sbin/tctl').with(ensure: 'link', target: '/opt/teleport-v2.4.0/teleport/tctl') }
  end

  context 'when specifying a different extract_path' do
    let(:params) do
      {
        extract_path: '/var/tmp',
      }
    end

    it { is_expected.to contain_file('/var/tmp').with(ensure: 'directory') }
    it { is_expected.to contain_file('/usr/local/bin/tctl').with(ensure: 'link', target: '/var/tmp/teleport/tctl') }
    it { is_expected.to contain_file('/usr/local/share/teleport').with(ensure: 'link', target: '/var/tmp/teleport/app') }
  end

  #### Config ####

  context 'when setting up config file by default' do
    it {
      is_expected.to contain_file('/etc/teleport.yaml').with(
        ensure: 'present',
        owner: 'root',
        group: 'root',
        mode: '0555',
      )
    }
    it {
      is_expected.to contain_file('/etc/teleport.yaml') \
        .with_content(/nodename: localhost\.localdomain/)
    }
  end

  context 'when configuring auth service' do
    let(:params) do
      {
        auth_enable: true,
        auth_listen_addr: '0.0.0.0',
        auth_listen_port: '8888',
      }
    end

    it { is_expected.to contain_file('/etc/teleport.yaml').with_content(/auth_service:\n  enabled: true\n  listen_addr: 0.0.0.0:8888\n/) }
  end

  context 'when configuring ssh service' do
    let(:params) do
      {
        ssh_enable: false,
        ssh_listen_addr: '0.0.0.0',
        ssh_listen_port: '8888',
      }
    end

    it { is_expected.to contain_file('/etc/teleport.yaml').with_content(/ssh_service:\n  enabled: false\n  listen_addr: 0.0.0.0:8888\n/) }
  end

  context 'when enabling SSL for proxy' do
    let(:params) do
      {
        proxy_ssl: true,
        proxy_ssl_key: '/var/ssl/teleport.key',
        proxy_ssl_cert: '/var/ssl/teleport.crt',
      }
    end

    it { is_expected.to contain_file('/etc/teleport.yaml').with_content(/https_key_file: \/var\/ssl\/teleport.key\n  https_cert_file: \/var\/ssl\/teleport.crt\n/) }
  end

  context 'when configuring proxy service' do
    let(:params) do
      {
        proxy_enable: true,
        proxy_listen_addr: '0.0.0.0',
        proxy_listen_port: '8888',
      }
    end

    it {
      is_expected.to contain_file('/etc/teleport.yaml') \
        .with_content(/proxy_service:\n  enabled: true\n  listen_addr: 0.0.0.0:8888\n/)
    }
  end

  context 'when configuring labels' do
    let(:params) do
      {
        labels: { 'role' => 'test_role', 'data' => 'test_data' },
      }
    end

    it { is_expected.to contain_file('/etc/teleport.yaml').with_content(/labels:\n    data: test_data\n    role: test_role/) }
  end

  context 'when listing auth servers' do
    let(:params) do
      {
        auth_servers: ['127.0.0.1:3030', '0.0.0.0:3030'],
      }
    end

    it { is_expected.to contain_file('/etc/teleport.yaml').with_content(/auth_servers:\n    - 127.0.0.1:3030\n    - 0.0.0.0:3030\n/) }
  end

  context 'when defining auth tokens' do
    let(:params) do
      {
        auth_service_tokens: ['node:VMU0mF8GbN'],
      }
    end

    it { is_expected.to contain_file('/etc/teleport.yaml').with_content(/tokens:\n    - node:VMU0mF8GbN\n/) }
  end

  ##### Service setup ####
  context 'when on unsupported operating system' do
    let(:facts) do
      {
        operatingsystem: 'Debian',
        operatingsystemrelease: '8',
      }
    end

    it { expect { is_expected.to compile }.to raise_error(/OS is currently/) }
  end

  context 'when on RHEL 7 system' do
    let(:facts) do
      {
        operatingsystem: 'CentOS',
        operatingsystemrelease: '7.1',
      }
    end

    it { is_expected.to contain_class('teleport').with_init_style('systemd') }
    it { is_expected.to contain_file('/lib/systemd/system/teleport.service').with_content(/teleport start --config/) }
  end

  context 'when on RHEL 6 system' do
    let(:facts) do
      {
        operatingsystem: 'CentOS',
        operatingsystemrelease: '6.7',
      }
    end

    it { is_expected.to contain_class('teleport').with_init_style('init') }
    it { is_expected.to contain_file('/etc/init.d/teleport').with_content(/start --config/) }
  end

  ### Service management ###

  context 'when by default service is_expected.to be started' do
    it { is_expected.to contain_service('teleport').with(ensure: 'running', enable: true) }
  end

  context 'when if not managing service' do
    let(:params) { { manage_service: false } }

    it { is_expected.not_to contain_service('teleport') }
  end

  context 'when config file notifies service' do
    it { is_expected.to contain_file('/etc/teleport.yaml').that_notifies('Service[teleport]') }
  end
end
