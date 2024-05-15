# @summary Configure backups for Slingshot fabric manager node.
#
# Configure backups for Slingshot fabric manager node.
#
# @param locations
#   Paths that need to be backed up.
#
# @example
#   include profile_slingshot::backup
#
class profile_slingshot::backup (
  Array[String]     $locations,
) {
  if ( lookup('profile_backup::client::enabled') ) {
    include profile_backup::client

    profile_backup::client::add_job { 'profile_slingshot':
      paths            => $locations,
      prehook_commands => [
        'fmn-create-backup -f /opt/slingshot/backup/fm-fabric-backup.tar',
      ],
    }
  }
}
