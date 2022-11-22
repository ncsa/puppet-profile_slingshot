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
    exec { 'dnf-modules':
      path        => $path,
      command     => 'dnf -y module reset container-tools nginx',
      before      => Exec['dnf-enable'],
      refreshonly => true,
    }
    exec { 'dnf-enable':
      path        => $path,
      command     => 'dnf -y module enable nginx:1.16 container-tools',
      refreshonly => true,
      before      => Package['slingshot-fmn-redhat']
    }
    package { 'slingshot-fmn-redhat':
      ensure  => installed,
      require => 
    }
  }
}
