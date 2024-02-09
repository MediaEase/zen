# modules/common.sh

## Overview

Contains a library of common functions used in the MediaEase project.

## Index

* [zen::common::git::clone](#zencommongitclone)
* [zen::common::git::get_release](#zencommongitgetrelease)
* [zen::common::environment::get::variable](#zencommonenvironmentgetvariable)
* [zen::common::fix::permissions](#zencommonfixpermissions)
* [zen::common::setting::load](#zencommonsettingload)
* [zen::common::capitalize::first](#zencommoncapitalizefirst)
* [zen::common::dashboard::log](#zencommondashboardlog)
* [zen::common:shell::color::randomizer](#zencommonshellcolorrandomizer)

## Git Functions

The following functions handle Git operations.

### zen::common::git::clone

Clones a Git repository into the specified directory.

#### Arguments

* **$1** (string): Full URL of the Git repository to clone.
* **$2** (string): Target directory where the repository will be cloned.
* **$3** (string): Specific branch to clone (optional).

#### Exit codes

* **0**: on successful cloning.
* **1**: on failure.

#### Output on stdout

* Clones the repository into the target directory.

### zen::common::git::get_release

Retrieves and extracts a release from a GitHub repository.

#### Arguments

* **$1** (string): Directory where the release will be extracted.
* **$2** (string): Full URL of the GitHub repository.
* **$3** (bool): Retrieve a prerelease (true) or stable release (false).
* **$4** (string): Name or pattern of the release file to be retrieved.

#### Exit codes

* **0**: on successful retrieval and extraction.
* **1**: on failure.

#### Output on stdout

* Downloads and extracts the specified release into the target directory.

## Environment Functions

The following functions are used for environment variable management.

### zen::common::environment::get::variable

Retrieves the value of a specified environment variable.

#### Arguments

* **$1** (string): Name of the environment variable to retrieve.

#### Exit codes

* **0**: if the variable is found.
* **1**: if the variable is not found.

#### Output on stdout

* Value of the specified environment variable.

### zen::common::fix::permissions

Fixes permissions of a specified path for a user and group.

#### Arguments

* **$1** (string): File system path whose permissions need fixing.
* **$2** (string): User for file/directory ownership.
* **$3** (string): Group for file/directory ownership.
* **$4** (string): Permissions for directories (e.g., '755').
* **$5** (string): Permissions for files (e.g., '644').

#### Exit codes

* **0**: if successful.
* **1**: if the path doesn't exist.

## Setting Functions

The following functions are used for managing application settings.

### zen::common::setting::load

Loads settings from the database into a global associative array.

#### Exit codes

* **0**: on successful loading.
* **1**: on failure.

### zen::common::capitalize::first

Capitalizes the first letter of a given string.

#### Arguments

* **$1** (string): String to be capitalized.

#### Output on stdout

* Transformed string with the first letter capitalized.

### zen::common::dashboard::log

Logs messages to a file for dashboard display.

#### Arguments

* **$1** (string): Message to be logged.

#### Output on stdout

* None.

### zen::common:shell::color::randomizer

Selects a random color code for shell output styling.

#### Output on stdout

* Echoes a random color code (yellow, magenta, cyan).

