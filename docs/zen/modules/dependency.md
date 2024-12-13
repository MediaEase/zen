# modules/dependency.sh

## Overview

Contains a library of functions used in the MediaEase Project for managing dependencies.

## Index

* [zen::dependency::apt::manage](#zendependencyaptmanage)

* [zen::dependency::apt::install::inline](#zendependencyaptinstallinline)

* [zen::dependency::apt::get_string](#zendependencyaptgetstring)

* [zen::dependency::apt::pin](#zendependencyaptpin)

* [zen::dependency::apt::update](#zendependencyaptupdate)

* [zen::dependency::apt::remove](#zendependencyaptremove)

* [zen::dependency::external::install](#zendependencyexternalinstall)

* [zen::dependency::apt::add_source](#zendependencyaptaddsource)

* [zen::dependency::apt::remove_source](#zendependencyaptremovesource)

* [zen::dependency::apt::update_source](#zendependencyaptupdatesource)


### zen::dependency::apt::manage

This function manages APT (Advanced Packaging Tool) dependencies based on the input action, software name, and additional options.
It processes various APT actions like install, update, upgrade, and check. The function uses a YAML file for dependency definitions.

> [!NOTE]
> Handles APT actions, reinstall, and non-interactive mode.

> [!WARNING]
> `yq` tool is required for parsing YAML files.

#### Arguments

* **$1** (string): APT action to perform (install, update, upgrade, check, etc.).
* **$2** (string): Name of the software for dependency management.
* **$3** (string): Additional options (reinstall, non-interactive, inline).

#### Output on stdout

* Executes apt-get commands based on input parameters.

### zen::dependency::apt::install::inline

This function installs APT dependencies inline, showing the progress. It uses apt-get for installation and dpkg-query to check existing installations.
Visual feedback is provided with colored output: red for failures and green for successful installations.

> [!NOTE]
> The function checks for existing installations before proceeding with installation.

#### Example

```bash
zen::dependency::apt::install::inline "package1 package2 package3"
```

#### Arguments

* **$1** (string): space-separated list of dependencies to install.

#### Output on stdout

* On success, displays the number of installed packages; on failure, shows failed package names.

### zen::dependency::apt::get_string

This function reads a YAML file containing APT dependencies for various software and returns a comma-separated string of dependencies for the specified software name.
It uses `yq` to parse the YAML file and converts spaces to commas.

> [!WARNING]
> `yq` tool is required for parsing YAML files.

#### Examples

```bash
dependencies=$(zen::dependency::apt::get_string "plex" ",")
```

```bash
# Outputs: "curl,libssl-dev,ffmpeg"
echo "$dependencies"
```

#### Arguments

* **$1** (string): The name of the software whose dependencies are to be retrieved.
* **$2** (string): The separator to use (comma or space). Defaults to space if not provided.

#### Output on stdout

* Outputs a string of APT dependencies separated by the specified separator.

### zen::dependency::apt::pin

This function modifies the list of APT packages pinned in a preference file.
It can add a package with an optional version specification or remove an existing package entry.
The function ensures that the preference file does not contain unnecessary blank lines after modifications.

> [!NOTE]
> The preference file is located at /etc/apt/preferences.d/mediaease.

#### Examples

```bash
zen::dependency::apt::pin add "curl" ">= 7.68.0"
```

```bash
zen::dependency::apt::pin remove "curl"
```

#### Arguments

* **$1** (string): The action to perform ("add" or "remove").
* **$2** (string): The package name to add or remove.
* **$3** (string): Optional: The version to pin the package to (e.g., ">= 2.8.4"). If not specified, the package will be pinned without a version constraint.

### zen::dependency::apt::update

This function performs system updates using apt-get commands. It updates the package lists and upgrades the installed packages.
Additionally, it handles locked dpkg situations and logs command execution for troubleshooting.

> [!NOTE]
> The function checks for and resolves locked dpkg situations before proceeding.

> [!CAUTION]
> Ensure that no other package management operations are running concurrently.

_Function has no arguments._

#### Output on stdout

* Executes apt-get update, upgrade, autoremove, and autoclean commands.

### zen::dependency::apt::remove

This function removes APT dependencies that are no longer needed by other installed software.
It reads dependencies from a YAML file and checks for exclusive use before removing them.

> [!NOTE]
> The function considers dependencies listed for the specified software in the YAML configuration.

> [!CAUTION]
> Ensure that the dependencies are not required by other software before removal.

#### Arguments

* **$1** (string): Name of the software for dependency removal.

#### Output on stdout

* Removes unused APT dependencies of the specified software.

### zen::dependency::external::install

This function installs external dependencies for a specified application as defined in a YAML configuration file.
It creates temporary scripts for each external dependency's install command and executes them.

> [!NOTE]
> Iterates over the external dependencies in the YAML file and executes their install commands.

> [!WARNING]
> Ensure the external dependencies do not conflict with existing installations.

#### Arguments

* **$1** (string): The name of the application for which to install external dependencies.

#### Output on stdout

* Executes installation commands for each external dependency of the specified application.

### zen::dependency::apt::add_source

This function adds new APT sources and their corresponding GPG keys from a YAML configuration file.
It handles different options like architecture, inclusion of source repositories, and GPG key processing.

> [!NOTE]
> The function evaluates and applies settings from the YAML configuration for the specified source(s).

> [!IMPORTANT]
> The architecture specified must match the system architecture.

> [!CAUTION]
> Ensure the GPG key is from a trusted source to avoid security risks.

#### Examples

```bash
zen::dependency::apt::add_source "php"
```

```bash
zen::dependency::apt::add_source "php" "nginx"
```

#### Arguments

* **$1** (string|array): Name of the source(s) as specified in the YAML configuration.

#### Output on stdout

* Adds new APT source(s) and GPG key(s) based on the YAML configuration.

### zen::dependency::apt::remove_source

This function removes an APT source and its GPG key.
It deletes the corresponding source list files and GPG keys for the specified source.

> [!CAUTION]
> Removing a source can impact system stability if other packages depend on it.

#### Arguments

* **$1** (string): Name of the source to be removed.

#### Output on stdout

* Removes specified APT source and its GPG key.

### zen::dependency::apt::update_source

This function updates APT sources based on the definitions in the apt_sources.yaml file.
It recreates source list files and GPG keys for each source defined in the configuration.

> [!NOTE]
> The function iterates over all sources defined in the YAML file and applies their configurations.

#### Output on stdout

* Updates APT sources and GPG keys based on the YAML configuration.

---
This file was auto-generated by [shdoc](https://github.com/MediaEase/shdoc)
