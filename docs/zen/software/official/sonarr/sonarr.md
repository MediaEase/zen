# software/sonarr/sonarr.sh

## Overview

Sonarr handler

## Index

* [zen::software::sonarr::add](#zensoftwaresonarradd)
* [zen::software::sonarr::config](#zensoftwaresonarrconfig)
* [zen::software::sonarr::update](#zensoftwaresonarrupdate)
* [zen::software::sonarr::remove](#zensoftwaresonarrremove)
* [zen::software::sonarr::backup](#zensoftwaresonarrbackup)
* [zen::software::sonarr::reset](#zensoftwaresonarrreset)
* [zen::software::sonarr::reinstall](#zensoftwaresonarrreinstall)

### zen::software::sonarr::add

Adds a Sonarr for a user, including downloading, configuring, and starting the service.

#### Arguments

* **$1** (string): The name of the application (Sonarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::sonarr::config

Configures Sonarr for a user, including setting up configuration files and proxy settings.

#### Example

```bash
# the following disables pre-release (develop):
zen::software::sonarr::config "false"
# the following enables pre-release (nightly):
zen::software::sonarr::config "true"
```

#### Arguments

* **$1** (string): Indicates whether to use a prerelease version of Sonarr.

### zen::software::sonarr::update

Updates Sonarr for a user, including stopping the service, downloading the latest release, and restarting.

### zen::software::sonarr::remove

Removes Sonarr for a user, including disabling and deleting the service and cleaning up files.

### zen::software::sonarr::backup

Creates a backup for Sonarr settings for a user.

### zen::software::sonarr::reset

Resets Sonarr settings for a user.

### zen::software::sonarr::reinstall

Reinstalls Sonarr for a user.

