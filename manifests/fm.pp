# @summary Install and Configure Fabric Manager
#
# Install and configure fabric manager
#
# @example
#   include profile_slingshot::fm
class profile_slingshot::fm (
  Boolean         $enable,
  Array[ String ] $required_pkgs,
  Hash            $yumrepo,
) {

  if ($enable) {
    $yumrepo_defaults = {
      ensure  => present,
      enabled => true,
    }
    ensure_resources( 'yumrepo', $yumrepo, $yumrepo_defaults )

    $packages_defaults = {
    }
    ensure_packages( $required_pkgs, $packages_defaults )
  } 
}