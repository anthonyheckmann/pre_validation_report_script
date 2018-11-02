Check supported OS version

Check docker version and that it is configured to autostart on reboot.

Check storage space available and that docker storage is set to a volume with appropriate storage

Either verify root access or that docker is configured to work without root

Check SELinux labels if SELinux is enabled. (https://hyperscience.atlassian.net/wiki/spaces/EN/pages/497876993/Bundle+File+Permissions)

After successful run, output a summary of OS, docker, etc versions.
