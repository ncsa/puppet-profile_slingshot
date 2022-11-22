# @summary Install and Configure Fabric Manager
#
# Install and configure fabric manager
#
# @example
#   include profile_slingshot::fm
class profile_slingshot::fm (
  Boolean         $enable,
  Array[ String ] $required_pkgs,
) {

  if ($enable) {
    #package { 'nginx'
    #provider    => 'dnfmodule',
    #  ensure      => 'nginx:1.16',
    #  enable_only => 'true',
    #}
    exec { 'dnf-enable':
      path        =>  $path,
      command     =>  'dnf config-manger --enable nginx:1.16 container-tools',
      refreshonly =>  true,
    }
    exec { 'dnf-modules':
      path        =>  $path,
      command     =>  'dnf -y module reset container-tools nginx',
      require     =>  Exec['dnf-enable'],
      refreshonly => true,
    }
    $packages_defaults = {
    }
    ensure_packages( $required_pkgs, $packages_defaults )
  } 
}
