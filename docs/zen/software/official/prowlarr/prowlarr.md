# software/prowlarr/prowlarr.sh

## Overview

Prowlarr handler

## Index

* [zen::software::prowlarr::add](#zensoftwareprowlarradd)
* [zen::software::prowlarr::config](#zensoftwareprowlarrconfig)
* [zen::software::prowlarr::update](#zensoftwareprowlarrupdate)
* [zen::software::prowlarr::remove](#zensoftwareprowlarrremove)
* [zen::software::prowlarr::backup](#zensoftwareprowlarrbackup)
* [zen::software::prowlarr::reset](#zensoftwareprowlarrreset)
* [zen::software::prowlarr::reinstall](#zensoftwareprowlarrreinstall)

### zen::software::prowlarr::add

Adds a Prowlarr for a user, including downloading, configuring, and starting the service.

### zen::software::prowlarr::config

Configures Prowlarr for a user, including setting up configuration files and proxy settings.

#### Example

```bash
# the following disables pre-release (develop):
zen::software::prowlarr::config "false"
# the following enables pre-release (nightly):
zen::software::prowlarr::config "true"
```

### zen::software::prowlarr::update

Updates Prowlarr for a user, including stopping the service, downloading the latest release, and restarting.

### zen::software::prowlarr::remove

Removes Prowlarr for a user, including disabling and deleting the service and cleaning up files.

### zen::software::prowlarr::backup

Creates a backup for Prowlarr settings for a user.

### zen::software::prowlarr::reset

Resets Prowlarr settings for a user.

### zen::software::prowlarr::reinstall

Reinstalls Prowlarr for a user.

