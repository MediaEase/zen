# Changelog for version 0.88.9-alpha

## 🎉 New Features

- `9d627c7` add support for executing user-defined files after downloading a git release (@tomcdj71)
- `c89d28b` enhance release retrieval process with version comparison and exit codes (@tomcdj71)
- `0e83d4b` implement Radarr configuration reading function to extract API key and ports (@tomcdj71)
- `1eef809` add Radarr authentication setup and refines service generation (@tomcdj71)
- `8a70d89` add prerelease check function to compare current version with GitHub releases (@tomcdj71)
- `9855f0d` add software reset functionality (@tomcdj71)
- `536a1cb` add software removal function (@tomcdj71)
- `b75e1ea` add function to retrieve application version via API (@tomcdj71)
- `19b947d` context-based backup directory selection (@tomcdj71)
- `16c6253` support for removing dependencies via apt (@tomcdj71)
- `0738f9e` add request management functions for API interactions in rhe new request.sh module (@tomcdj71)
- `1800a55` update service_monitor.sh to retrieve monitored services from SQLite database (@tomcdj71)

## 🩹 Bug Fixes

- `38649ab` enhance release version verification and error handling in git.sh (@tomcdj71)
- `304db35` service stop handling and adds delays (@tomcdj71)
- `05d6d86` add port_range to exported variables in autogen function (@tomcdj71)
- `9d643ad` update infobox  to conditionally display username and password (@tomcdj71)
- `4110512` extract the correct user password (@tomcdj71)
- `7d456e4` vault initialization and key decoding issues (@tomcdj71)
- `9944069` remove redundant database query execution (@tomcdj71)
- `0caea48` database file handling in zen_autocomplete script (@tomcdj71)

## 🚀 Chores

- `7cd5592` updates version numbers across multiple scripts (@tomcdj71)
- `a10fa4a` add executable file paths for Lidarr, Sonarr, Readarr, Radarr, Prowlarr, and their 4K variants (@tomcdj71)
- `8407579` removes test executable file list (@tomcdj71)
- `994bdbe` enhance Radarr update process with additional checks and permissions (@tomcdj71)
- `048b574` simplify Radarr configuration function by removing prerelease argument and cleaning up comments (@tomcdj71)
- `b80a75a` add database path to Radarr configuration (@tomcdj71)
- `e397463` add validation for api_service declaration (@tomcdj71)

## 🌐 Internationalization

- `fe7077c` add new translation strings (@tomcdj71)
- `ad74669` add new translations (@tomcdj71)

## ♻️ Refactors

- `9f831ca` Radarr script (@tomcdj71)
- `0f60deb` update service validation to use configuration array and improve JSON handling (@tomcdj71)
- `096b3a6` service generation to use config array (@tomcdj71)

**Full Changelog**: https://github.com/MediaEase/zen/compare/v0.76.9-alpha...0.88.9-alpha
