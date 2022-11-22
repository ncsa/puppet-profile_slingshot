# @summary Install and Configure Fabric Manager
#
# Install and configure fabric manager
#
# @example
#   include profile_slingshot::fm
class profile_slingshot::fm (
  Boolean         $enable,
  Array[ String ] $required_pkgs,
  String          $nginxversion
) {

  if ($enable) {
    package( 'nginx'
      enable_only => true
      ensure      => $nginxversion
    )
    $packages_defaults = {
    }
    ensure_packages( $required_pkgs, $packages_defaults )
  } 
}
