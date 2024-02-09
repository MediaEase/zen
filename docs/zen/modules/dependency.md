# modules/dependency.sh

## Overview

Contains a library of functions used in the MediaEase Project for managing dependencies.

## Index

* [zen::dependency::apt::manage](#zendependencyaptmanage)
* [zen::dependency::apt::install::inline](#zendependencyaptinstallinline)
* [zen::dependency::apt::update](#zendependencyaptupdate)
* [zen::dependency::apt::remove](#zendependencyaptremove)
* [zen::dependency::external::build](#zendependencyexternalbuild)
* [zen::dependency::python::build](#zendependencypythonbuild)

### zen::dependency::apt::manage

Manages APT dependencies for the specified software.

#### Arguments

* **$1** (string): The APT action to perform (install, update, upgrade, check, etc.).
* **$2** (string): Name of the software for dependency management.
* **$3** (string): Additional options (reinstall, non-interactive, inline).

#### Output on stdout

* Executes various apt-get commands based on input parameters.

### zen::dependency::apt::install::inline

Installs APT dependencies inline with progress display.

#### Arguments

* **...** (string): Space-separated list of dependencies to install.

#### Output on stdout

* Installs dependencies with colored success/failure indicators.

### zen::dependency::apt::update

Updates package lists and upgrades installed packages.

_Function has no arguments._

#### Output on stdout

* Executes apt-get update, upgrade, autoremove, and autoclean commands.

### zen::dependency::apt::remove

Removes APT dependencies not needed by other software.

#### Arguments

* **$1** (string): Name of the software for dependency removal.

#### Output on stdout

* Removes unused APT dependencies of the specified software.

### zen::dependency::external::build

Installs external dependencies based on YAML configuration.

#### Arguments

* **$1** (string): Name of the software for external dependency installation.

#### Output on stdout

* Executes custom installation commands for external dependencies.

### zen::dependency::python::build

Installs Python dependencies based on YAML configuration.

#### Arguments

* **$1** (string): Name of the software for Python dependency installation.

#### Output on stdout

* Installs Python packages using pip.

