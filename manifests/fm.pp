# @summary Install and Configure Fabric Manager
#
# Install and configure fabric manager
#
# @param additional_packages
#   Additional packages beyond the base FMN software install.
#
# @param enable
#   Enable fabric manager management.
#
# @param fabric_mgr_ips
#   IP addresses for fabric manager(s).
#
# @param firewall_allowed_subnets
#   Trusted CIDR ranges for managed Slingshot switches.
#
# @param fm_version
#   Fabric manager software version.
#
# @param nginx_version
#   nginx version needed for fabric manager software.
#
# @param php_version
#   PHP version needed for fabric manager software. (As of Slingshot
#   version 2.2.0, and possibly earlier, PHP is no longer needed.)
#
# @param sshkey_priv
#   Private key for fabric manager SSH.
#
# @param sshkey_pub
#   Public key for fabric manager SSH.
#
# @param sshkey_type
#   SSH key type ("rsa", etc.) for fabric manager SSH.
#
# @example
#   include profile_slingshot::fm
class profile_slingshot::fm (
  Hash                $additional_packages,
  Boolean             $enable,
  Array               $fabric_mgr_ips,
  Hash[String,String] $firewall_allowed_subnets,
  String              $fm_version,
  String              $nginx_version,
  String              $php_version,
  String              $sshkey_priv,
  String              $sshkey_pub,
  String              $sshkey_type,
) {
  if ($enable) {
    # MANAGE SSH KEYS
    ## Secure sensitive data to prevent it showing in logs
    $pubkey = Sensitive( $sshkey_pub )
    $privkey = Sensitive( $sshkey_priv )

    ## Local variables
    $sshdir = '/root/.ssh'
    $file_defaults = {
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0600',
      require => File[$sshdir],
    }

    ## Define unique parameters of each resource
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

    ## Ensure the resources
    ensure_resources( 'file', $data, $file_defaults )

    # MANAGE SSHD_CONFIG

    ## Params for sshd_config
    $params = {
      'PasswordAuthentication'  => 'yes',  # needed for setup
      'PubkeyAuthentication'    => 'yes',
      'PermitRootLogin'         => 'yes',  # needed for setup
      'AuthenticationMethods' => 'publickey password',  # password needed for setup
      'Banner'                => 'none',
    }

    ## Configure sshd_config
    ::sshd::allow_from { 'profile_slingshot_fm':
      hostlist                => $fabric_mgr_ips,
      users                   => [root],
      additional_match_params => $params,
    }

    # MANAGE AUTHORIZED SSH KEYS FOR ROOT

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

    # INSTALL SLINGSHOT FABRIC MANAGER SOFTWARE

    $dnf_module_command = "dnf -y module reset php nginx && dnf -y module enable php:${php_version} nginx:${nginx_version} container-tools"
    exec { 'slingshot-dnf-modules':
      provider => shell,
      command  => $dnf_module_command,
      unless   => "dnf module list nginx | grep ${nginx_version} | egrep -i \'${nginx_version} \\[[e|d]\\]\' || dnf module list php | grep ${php_version} | egrep -i \'${php_version} \\[[e|d]\\]\'",
      before   => Package['slingshot-fmn-redhat'],
    }

    package { 'slingshot-fmn-redhat':
      ensure  => $fm_version,
      require => Exec['slingshot-dnf-modules'],
    }

    # install additional packages
    $default = { 'ensure' => 'installed' }
    ## find keys without a value and add default value
    $sane_pkg_list = $additional_packages.map |$key, $val| {
      if $val {[$key, $val] }
      else {[$key, $default] }
    }.convert_to(Hash)
    ensure_packages( $sane_pkg_list )

    # START FABRIC MANAGER SERVICES

    service { 'slingshot-nginx-secure':
      ensure   => 'running',
      provider => 'redhat',
    }
    service { 'fabric-manager':
      ensure   => 'running',
      provider => 'redhat',
    }

    # ENSURE CORRECT ORDERING

    Exec['slingshot-dnf-modules'] -> Package['slingshot-fmn-redhat'] -> Service['slingshot-nginx-secure'] -> Service['fabric-manager']
  }

  # MANAGE THE FIREWALL

  $firewall_allowed_subnets.each | $location, $source_cidr | {
    firewall { "400 allow slingshot any for ${location}":
      proto  => 'all',
      source => $source_cidr,
      action => accept,
    }
  }
}
