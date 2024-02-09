# modules/software.sh

## Overview

Contains a library of functions used in the MediaEase Project for managing softwares.

## Index

* [zen::software::is::installed](#zensoftwareisinstalled)
* [zen::software::port_randomizer](#zensoftwareportrandomizer)
* [zen::software::infobox](#zensoftwareinfobox)
* [zen::software::options::process](#zensoftwareoptionsprocess)
* [zen::software::backup::create](#zensoftwarebackupcreate)
* [zen::software::get_config_key_value](#zensoftwaregetconfigkeyvalue)
* [zen::software::autogen](#zensoftwareautogen)

### zen::software::is::installed

Checks if a specific software is installed for a given user.

#### Example

```bash
zen::software::is::installed "software_name" "user_id"
[[ $(zen::software::is::installed "subsonic" 6) ]] && echo "yes" || echo "no"
```

#### Arguments

* **$1** (string): Name (altname) of the software.
* **$2** (string): User ID to check the software installation for.

### zen::software::port_randomizer

Generates a random port number within a specified range for an application.

#### Example

```bash
zen::software::port_randomizer "app_name" "port_type" "config_file"
```

#### Arguments

* **$1** (string): Name of the application.
* **$2** (string): Type of port to generate (default, ssl).
* **$3** (string): Path to the configuration file.

### zen::software::infobox

Builds the header or footer for the software installer.

#### Example

```bash
zen::software::infobox "app_name" "shell_color" "action" "infobox_type"
```

#### Arguments

* **$1** (string): Name of the application.
* **$2** (string): Color to use for the text.
* **$3** (string): Action being performed (add, update, backup, reset, remove, reinstall).
* **$4** (string): "intro" for header, "outro" for footer.
* **$5** (string): (optional) Username to display in the infobox.
* **$6** (string): (optional) Password to display in the infobox.

### zen::software::options::process

Processes software options from a comma-separated string.

#### Example

```bash
@note Variables are exported and used in other functions.
shellcheck disable=SC2034
```

#### Arguments

* **$1** (string): String of options in "option1=value1,option2=value2" format.

### zen::software::backup::create

Handles the creation of software backups.

#### Example

```bash
zen::software::backup::create "app_name"
```

#### Arguments

* **$1** (string): Name of the application.

### zen::software::get_config_key_value

Retrieves a key/value from a YAML configuration file.

#### Example

```bash
zen::software::get_config_key_value "config_file_path" "yq_expression"
```

#### Arguments

* **$1** (string): Path to the YAML configuration file.
* **$2** (string): 'yq' expression to evaluate in the configuration file.

### zen::software::autogen

Automatically generates random values for specified keys.

#### Example

```bash
zen::software::autogen
```

