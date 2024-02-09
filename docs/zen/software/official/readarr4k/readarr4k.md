# software/readarr4k/readarr4k.sh

## Overview

Readarr4k handler

## Index

* [zen::software::readarr4k::add](#zensoftwarereadarr4kadd)
* [zen::software::readarr4k::config](#zensoftwarereadarr4kconfig)
* [zen::software::readarr4k::update](#zensoftwarereadarr4kupdate)
* [zen::software::readarr4k::remove](#zensoftwarereadarr4kremove)
* [zen::software::readarr4k::backup](#zensoftwarereadarr4kbackup)
* [zen::software::readarr4k::reset](#zensoftwarereadarr4kreset)
* [zen::software::readarr4k::reinstall](#zensoftwarereadarr4kreinstall)

### zen::software::readarr4k::add

Adds a Readarr4k for a user, including downloading, configuring, and starting the service.

### zen::software::readarr4k::config

Configures Readarr4k for a user, including setting up configuration files and proxy settings.

#### Example

```bash
# the following disables pre-release (develop):
zen::software::readarr4k::config "false"
# the following enables pre-release (nightly):
zen::software::readarr4k::config "true"
```

#### Arguments

* **$1** (string): Indicates whether to use a prerelease version of Readarr4k.

### zen::software::readarr4k::update

Updates Readarr4k for a user, including stopping the service, downloading the latest release, and restarting.

### zen::software::readarr4k::remove

Removes Readarr4k for a user, including disabling and deleting the service and cleaning up files.

### zen::software::readarr4k::backup

Creates a backup for Readarr4k settings for a user.

### zen::software::readarr4k::reset

Resets Readarr4k settings for a user.

### zen::software::readarr4k::reinstall

Reinstalls Readarr4k for a user.

