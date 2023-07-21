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
