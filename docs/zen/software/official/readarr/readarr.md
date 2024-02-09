# software/readarr/readarr.sh

## Overview

Readarr handler

## Index

* [zen::software::readarr::add](#zensoftwarereadarradd)
* [zen::software::readarr::config](#zensoftwarereadarrconfig)
* [zen::software::readarr::update](#zensoftwarereadarrupdate)
* [zen::software::readarr::remove](#zensoftwarereadarrremove)
* [zen::software::readarr::backup](#zensoftwarereadarrbackup)
* [zen::software::readarr::reset](#zensoftwarereadarrreset)
* [zen::software::readarr::reinstall](#zensoftwarereadarrreinstall)

### zen::software::readarr::add

Adds a Readarr for a user, including downloading, configuring, and starting the service.

#### Arguments

* **$1** (string): The name of the application (Readarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::readarr::config

Configures Readarr for a user, including setting up configuration files and proxy settings.

#### Example

```bash
# the following disables pre-release (develop):
zen::software::readarr::config "false"
# the following enables pre-release (nightly):
zen::software::readarr::config "true"
```

#### Arguments

* **$1** (string): The name of the application (Readarr).
* **$2** (string): A sanitized version of the application name for display.
* **$3** (string): Indicates whether to use a prerelease version of Readarr.

### zen::software::readarr::update

Updates Readarr for a user, including stopping the service, downloading the latest release, and restarting.

#### Arguments

* **$1** (string): The name of the application (Readarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::readarr::remove

Removes Readarr for a user, including disabling and deleting the service and cleaning up files.

#### Arguments

* **$1** (string): The name of the application (Readarr).
* **$2** (string): A sanitized version of the application name for display.

### zen::software::readarr::backup

Creates a backup for Readarr settings for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Readarr).

### zen::software::readarr::reset

Resets Readarr settings for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Readarr).

### zen::software::readarr::reinstall

Reinstalls Readarr for a user.

#### Arguments

* **$1** (string): The username of the user.
* **$2** (string): The name of the application (Readarr).

