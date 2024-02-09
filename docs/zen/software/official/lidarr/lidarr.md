# software/lidarr/lidarr.sh

## Overview

Lidarr handler

## Index

* [zen::software::lidarr::add](#zensoftwarelidarradd)
* [zen::software::lidarr::config](#zensoftwarelidarrconfig)
* [zen::software::lidarr::update](#zensoftwarelidarrupdate)
* [zen::software::lidarr::remove](#zensoftwarelidarrremove)
* [zen::software::lidarr::backup](#zensoftwarelidarrbackup)
* [zen::software::lidarr::reset](#zensoftwarelidarrreset)
* [zen::software::lidarr::reinstall](#zensoftwarelidarrreinstall)

### zen::software::lidarr::add

Adds a Lidarr for a user, including downloading, configuring, and starting the service.

#### Arguments

* **$1** (string): The name of the application (Lidarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::lidarr::config

Configures Lidarr for a user, including setting up configuration files and proxy settings.

#### Example

```bash
# the following disables pre-release (develop):
zen::software::lidarr::config "false"
# the following enables pre-release (nightly):
zen::software::lidarr::config "true"
```

#### Arguments

* **$1** (string): The name of the application (Lidarr).
* **$2** (string): A sanitized version of the application name for display.
* **$3** (string): Indicates whether to use a prerelease version of Lidarr.

### zen::software::lidarr::update

Updates Lidarr for a user, including stopping the service, downloading the latest release, and restarting.

#### Arguments

* **$1** (string): The name of the application (Lidarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::lidarr::remove

Removes Lidarr for a user, including disabling and deleting the service and cleaning up files.

#### Arguments

* **$1** (string): The name of the application (Lidarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::lidarr::backup

Creates a backup for Lidarr settings for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Lidarr).

### zen::software::lidarr::reset

Resets Lidarr settings for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Lidarr).

### zen::software::lidarr::reinstall

Reinstalls Lidarr for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Lidarr).

