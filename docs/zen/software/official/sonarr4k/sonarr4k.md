# software/sonarr4k/sonarr4k.sh

## Overview

Sonarr4k handler

## Index

* [zen::software::sonarr4k::add](#zensoftwaresonarr4kadd)
* [zen::software::sonarr4k::config](#zensoftwaresonarr4kconfig)
* [zen::software::sonarr4k::update](#zensoftwaresonarr4kupdate)
* [zen::software::sonarr4k::remove](#zensoftwaresonarr4kremove)
* [zen::software::sonarr4k::backup](#zensoftwaresonarr4kbackup)
* [zen::software::sonarr4k::reset](#zensoftwaresonarr4kreset)
* [zen::software::sonarr4k::reinstall](#zensoftwaresonarr4kreinstall)

### zen::software::sonarr4k::add

Adds a Sonarr4k for a user, including downloading, configuring, and starting the service.

#### Arguments

* **$1** (string): The name of the application (Sonarr4k).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::sonarr4k::config

Configures Sonarr4k for a user, including setting up configuration files and proxy settings.

#### Example

```bash
# the following disables pre-release (develop):
zen::software::sonarr4k::config "false"
# the following enables pre-release (nightly):
zen::software::sonarr4k::config "true"
```

#### Arguments

* **$1** (string): Indicates whether to use a prerelease version of Sonarr4k.

### zen::software::sonarr4k::update

Updates Sonarr4k for a user, including stopping the service, downloading the latest release, and restarting.

### zen::software::sonarr4k::remove

Removes Sonarr4k for a user, including disabling and deleting the service and cleaning up files.

### zen::software::sonarr4k::backup

Creates a backup for Sonarr4k settings for a user.

### zen::software::sonarr4k::reset

Resets Sonarr4k settings for a user.

### zen::software::sonarr4k::reinstall

Reinstalls Sonarr4k for a user.

