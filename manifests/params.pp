# === Class: teleport::params
#
# This class is meant to be called from the main class
# It sets variables according to platform
class teleport::params {
  $version                  = 'v2.5.7'
  $extract_path             = "/opt/teleport/${version}"
  $archive_path             = '/tmp/teleport.tar.gz'
  $bin_dir                  = '/usr/local/bin'
  $assets_dir               = '/usr/local/share/teleport'
  $config_path              = '/etc/teleport.yaml'
  $nodename                 = $facts['fqdn']
  $auth_type                = 'local'
  $auth_second_factor       = 'otp'
  $auth_u2f_app_id          = 'https://localhost:3080'
  $auth_u2f_facets          = ['https://localhost:3080']
  $auth_cluster_name        = undef
  $ssh_label_commands       = [{
    name    => 'arch',
    command => '[uname, -p]',
    period  => '1h0m0s',
  }]
  $ssh_permit_user_env      = false
  $proxy_tunnel_listen_addr = '127.0.0.1'
  $proxy_tunnel_listen_port = '3024'

  case $facts['os']['name'] {
    'RedHat', 'CentOS': {
      if versioncmp($facts['os']['release']['major'], '7') < 0 {
        $init_style  = 'init'
      } else {
        $init_style  = 'systemd'
      }
    }
    'Debian': {
      if versioncmp($facts['os']['release']['major'], '8') < 0 {
        fail('OS is currently not supported')
      } else {
        $init_style = 'systemd'
      }
    }
    'Ubuntu': {
      if versioncmp($facts['os']['release']['major'], '15') < 0 {
        fail('OS is currently not supported')
      } else {
        $init_style = 'systemd'
      }
    }
    default: { fail('Unsupported OS') }
  }
}
