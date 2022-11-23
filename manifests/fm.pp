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
  String          $cert,
  String          $key,
  Array[ String ] $required_pkgs,
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
      ensure  => installed,
      require => Exec['slingshot-dnf-modules'],
    }
    file { 'fabric-manager-key'
      contents => $key,
      ensure   => '/opt/slingshot/config/ssl/fabric-manager.key'
      mode    => '0600'
      owner    => 'root',
      group    => 'root',
    }

    file { 'fabric-manager-cert'
      contents => $cert,
      ensure   => '/opt/slingshot/config/ssl/fabric-manager.cert',
      mode     => '0644',
      owner    => 'root',
      group    => 'root',
    }

    Exec['slingshot-dnf-modules'] -> Package['slingshot-fmn-redhat']
  }
}
