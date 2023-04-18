# @summary Install and Configure Fabric Manager
#
# Install and configure fabric manager
#
# @example
#   include profile_slingshot::fm
class profile_slingshot::fm (
  Boolean         $enable,
  String          $nginx_version,
  String          $php_version,
  String          $fm_version,
  String          $cert,
  String          $key,
  Array $fabric_mgr_ips,
  Hash[String,String] $firewall_allowed_subnets,
  String $sshkey_pub,
  String $sshkey_priv,
  String $sshkey_type,
) {

  if ($enable) {
      # Secure sensitive data to prevent it showing in logs
    $pubkey = Sensitive( $sshkey_pub )
    $privkey = Sensitive( $sshkey_priv )

    # Local variables

    $sshdir = '/root/.ssh'

    $file_defaults = {
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0600',
      require =>  File[ $sshdir ],
    }


    # Define unique parameters of each resource
    $data = {
      $sshdir => {
        ensure => directory,
        mode   => '0700',
        require => [],
      },
      "${sshdir}/id_${sshkey_type}" => {
        content => $privkey,
      },
      "${sshdir}/id_${sshkey_type}.pub" => {
        content => $pubkey,
        mode    => '0644',
      },
    }

    # Ensure the resources
    ensure_resources( 'file', $data, $file_defaults )
 
    $params = {
      'PubkeyAuthentication'  => 'yes',
      'PermitRootLogin'       => 'without-password',
      'AuthenticationMethods' => 'publickey',
      'Banner'                => 'none',
    }

    ::sshd::allow_from{ 'profile_slingshot_fm':
      hostlist                => $fabric_mgr_ips,
      users                   => [ root ],
      additional_match_params => $params,
    }


    $pubkey_parts = split( $sshkey_pub, ' ' )
    $key_type = $pubkey_parts[0]
    $key_data = $pubkey_parts[1]
    $key_name = $pubkey_parts[2]

    ssh_authorized_key { $key_name :
      ensure => present,
      user   => 'root',
      type   => $key_type,
      key    => $key_data,
    }
    $activebackupips = join($fabric_mgr_ips, "\n")
    $activebackup = sprintf("%s\n", $activebackupips)
    file { "/opt/slingshot/config/active_standby.dat":
      path    => "/opt/slingshot/config/active_standby.dat",
      content => $activebackup ,
    }
    #exec { 'dnf-modules':
    #  path        => $path,
    #  command     => 'dnf -y module reset php container-tools nginx',
    #  require      => Exec['dnf-enable'],
    #  refreshonly => true,
    #}i
    $dnf_module_command = "dnf -y module reset php container-tools nginx && dnf -y module enable php:$php_version nginx:$nginx_version container-tools"
    exec { 'slingshot-dnf-modules':
      path     => $path,
      provider => shell,
      command  => $dnf_module_command,
      unless   => "dnf module list nginx | grep ${nginx_version} | egrep -i \'${nginx_version} \\[[e|d]\\]\' || dnf module list php | grep ${php_version} | egrep -i \'${php_version} \\[[e|d]\\]\'",
      before   => Package['slingshot-fmn-redhat'],
    }
    package { 'slingshot-fmn-redhat':
      ensure  => $fm_version,
      require => Exec['slingshot-dnf-modules'],
    }
    file { '/opt/slingshot/config/ssl/fabric-manager.key':
      content => $key,
      mode    => '0600',
      owner    => 'root',
      group    => 'root',
      notify  => Service['slingshot-nginx-secure'],
    }

    file { '/opt/slingshot/config/ssl/fabric-manager.crt':
      content => $cert,
      mode     => '0644',
      owner    => 'root',
      group    => 'root',
      notify  => Service['slingshot-nginx-secure'],
    }
    service { 'slingshot-nginx-secure':
      ensure   => 'running',
      provider => 'redhat',
    }

    Exec['slingshot-dnf-modules'] -> Package['slingshot-fmn-redhat'] -> File['/opt/slingshot/config/ssl/fabric-manager.crt'] -> File['/opt/slingshot/config/ssl/fabric-manager.key'] -> Service['slingshot-nginx-secure']
  }
    
  $firewall_allowed_subnets.each | $location, $source_cidr |
  {
    firewall { "400 allow slingshot any for ${location}":
      proto  => 'all',
      source => $source_cidr,
      action => accept,
    }
  }
}
