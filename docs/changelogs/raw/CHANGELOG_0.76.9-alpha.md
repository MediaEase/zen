# Changelog for version 0.76.9-alpha

## 🎉 New Features

- `24c420d` add service_monitor.sh script for real-time log monitoring and JSON alerting (@tomcdj71)
- `b8cd03c` (grafana) add grafana preliminary support (@tomcdj71)
- `4ead1af` `zen::software::port_randomizer` add a condition for generate grafana port ranges (@tomcdj71)
- `cd7125a` (workspace) `zen::workspace::go::build` function (@tomcdj71)
- `bd9c679` (workspace) `zen::workspace::go::uninstall` function (@tomcdj71)
- `07aa11f` (workspace) `zen::workspace::go::install` function (@tomcdj71)

## 🩹 Bug Fixes

- `f6a1c2c` update software options processing to include prerelease status based on branch value (@tomcdj71)
- `542306f` update software options handling to use software_options for improved consistency (@tomcdj71)
- `fc92a3e` update software configuration handling to use options for improved consistency (@tomcdj71)
- `4fa0497` add release_name entries for various software configurations (@tomcdj71)
- `5ab2ea9` refactor Radarr functions to use config variables for improved consistency and maintainability (@tomcdj71)
- `16ce1ec` update software options handling to include software_version and prerelease status (@tomcdj71)
- `81f35e4` update jq commands to use variables for improved readability and maintainability (@tomcdj71)
- `7a1f762` update database file path retrieval to use environment variable (@tomcdj71)
- `5838d59` streamline database query execution and improve error handling (@tomcdj71)
- `8a12c4f` add session_id to user_columns in user loading function (@tomcdj71)
- `27918e8` add missing multi-user support in Readarr4K configuration (@tomcdj71)

## 🏗️ Build System & Dependencies

- `9a7fa11` add grafana dependencies (@tomcdj71)
- `49a70af` add telegraf apt source (@tomcdj71)
- `5c957ac` add fluentbit apt source (@tomcdj71)
- `67000ef` add grafana apt source (@tomcdj71)

## 🚀 Chores

- `d04d2ce` update software repository references to use config array (@tomcdj71)
- `05ace46` adds ui_options to various software configurations (@tomcdj71)
- `3342623` removes deprecated port configurations from various software configs (@tomcdj71)
- `23960e6` updates group classifications in config files (@tomcdj71)
- `6d93a49` removes deprectaed description fields from config files (@tomcdj71)

## 📝 Documentation

- `3ebbeff` update documentation for v0.75.9-alpha [automated] (@tomcdj71)
- `822f6ef` update documentation for v0.75.9-alpha [automated] (@tomcdj71)

## 🤷 Other Changes

- `74e6aba` Simplifies Go build function (@tomcdj71)

## Other Changes

- `cde595b` update copyright notice (@tomcdj71)

**Full Changelog**: https://github.com/MediaEase/zen/compare/v0.70.9-alpha...0.76.9-alpha
