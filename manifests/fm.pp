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
  Hash[String,String] $firewall_allowed_subnets,
) {

  if ($enable) {
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
      notify  => Service['slingshot-nginx'],
    }

    file { '/opt/slingshot/config/ssl/fabric-manager.crt':
      content => $cert,
      mode     => '0644',
      owner    => 'root',
      group    => 'root',
      notify  => Service['slingshot-nginx'],
    }
    service { 'slingshot-nginx':
      ensure   => 'running',
      provider => 'redhat',
    }

    Exec['slingshot-dnf-modules'] -> Package['slingshot-fmn-redhat'] -> File['/opt/slingshot/config/ssl/fabric-manager.crt'] -> File['/opt/slingshot/config/ssl/fabric-manager.key'] -> Service['slingshot-nginx']
  }
    $firewall_allowed_subnets.each | $location, $source_cidr |
  {
    firewall { "400 allow HTTP on tcp port 80 from ${location}":
      dport  => '80',
      proto  => tcp,
      source => $source_cidr,
      action => accept,
    }
  }
  $firewall_allowed_subnets.each | $location, $source_cidr |
  {
    firewall { "400 allow HTTPS on tcp port 443 from ${location}":
      dport  => '80',
      proto  => tcp,
      source => $source_cidr,
      action => accept,
    }
  }
  $firewall_allowed_subnets.each | $location, $source_cidr |
  {
    firewall { "400 allow slingshot-keystore on tcp port 9000 from ${location}":
      dport  => '9000',
      proto  => tcp,
      source => $source_cidr,
      action => accept,
    }
  }
  $firewall_allowed_subnets.each | $location, $source_cidr |
  {
    firewall { "400 allow slingshot on tcp port 8000 from ${location}":
      dport  => '8000',
      proto  => tcp,
      source => $source_cidr,
      action => accept,
    }
  }
  $firewall_allowed_subnets.each | $source_cidr |
  {
    firewall { "400 allow slingshot any from ${location}":
      proto  => all,
      source => $source_cidr,
      action => accept,
    }
  }
}
