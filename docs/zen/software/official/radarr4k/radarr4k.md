# software/radarr4k/radarr4k.sh

## Overview

Radarr4k handler

## Index

* [zen::software::radarr4k::add](#zensoftwareradarr4kadd)
* [zen::software::radarr4k::config](#zensoftwareradarr4kconfig)
* [zen::software::radarr4k::update](#zensoftwareradarr4kupdate)
* [zen::software::radarr4k::remove](#zensoftwareradarr4kremove)
* [zen::software::radarr4k::backup](#zensoftwareradarr4kbackup)
* [zen::software::radarr4k::reset](#zensoftwareradarr4kreset)
* [zen::software::radarr4k::reinstall](#zensoftwareradarr4kreinstall)

### zen::software::radarr4k::add

Adds a Radarr4k for a user, including downloading, configuring, and starting the service.

#### Arguments

* **$1** (string): The name of the application (Radarr4k).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::radarr4k::config

Configures Radarr4k for a user, including setting up configuration files and proxy settings.

#### Example

```bash
# the following disables pre-release (develop):
zen::software::radarr4k::config "false"
# the following enables pre-release (nightly):
zen::software::radarr4k::config "true"
```

#### Arguments

* **$1** (string): The name of the application (Radarr4k).
* **$2** (string): A sanitized version of the application name for display.
* **$3** (string): Indicates whether to use a prerelease version of Radarr4k.

### zen::software::radarr4k::update

Updates Radarr4k for a user, including stopping the service, downloading the latest release, and restarting.

#### Arguments

* **$1** (string): The name of the application (Radarr4k).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::radarr4k::remove

Removes Radarr4k for a user, including disabling and deleting the service and cleaning up files.

#### Arguments

* **$1** (string): The name of the application (Radarr4k).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::radarr4k::backup

Creates a backup for Radarr4k settings for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Radarr4k).

### zen::software::radarr4k::reset

Resets Radarr4k settings for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Radarr4k).

### zen::software::radarr4k::reinstall

Reinstalls Radarr4k for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Radarr4k).

