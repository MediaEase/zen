# software/radarr/radarr.sh

## Overview

Radarr handler

## Index

* [zen::software::radarr::add](#zensoftwareradarradd)
* [zen::software::radarr::config](#zensoftwareradarrconfig)
* [zen::software::radarr::update](#zensoftwareradarrupdate)
* [zen::software::radarr::remove](#zensoftwareradarrremove)
* [zen::software::radarr::backup](#zensoftwareradarrbackup)
* [zen::software::radarr::reset](#zensoftwareradarrreset)
* [zen::software::radarr::reinstall](#zensoftwareradarrreinstall)

### zen::software::radarr::add

Adds a Radarr for a user, including downloading, configuring, and starting the service.

#### Arguments

* **$1** (string): The name of the application (Radarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::radarr::config

Configures Radarr for a user, including setting up configuration files and proxy settings.

#### Example

```bash
# the following disables pre-release (develop):
zen::software::radarr::config "false"
# the following enables pre-release (nightly):
zen::software::radarr::config "true"
```

#### Arguments

* **$1** (string): The name of the application (Radarr).
* **$2** (string): A sanitized version of the application name for display.
* **$3** (string): Indicates whether to use a prerelease version of Radarr.

### zen::software::radarr::update

Updates Radarr for a user, including stopping the service, downloading the latest release, and restarting.

#### Arguments

* **$1** (string): The name of the application (Radarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::radarr::remove

Removes Radarr for a user, including disabling and deleting the service and cleaning up files.

#### Arguments

* **$1** (string): The name of the application (Radarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::radarr::backup

Creates a backup for Radarr settings for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Radarr).

### zen::software::radarr::reset

Resets Radarr settings for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Radarr).

### zen::software::radarr::reinstall

Reinstalls Radarr for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Radarr).

