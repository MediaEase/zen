# modules/common.sh

## Overview

Contains a library of common functions used in the MediaEase project.

## Index

* [zen::common::environment::get::variable](#zencommonenvironmentgetvariable)

* [zen::common::environment::set::variable](#zencommonenvironmentsetvariable)

* [zen::common::bashrc::append](#zencommonbashrcappend)

* [zen::common::setting::load](#zencommonsettingload)

* [zen::common::dashboard::log](#zencommondashboardlog)

* [zen::common::capitalize::first](#zencommoncapitalizefirst)

* [zen::common::lowercase](#zencommonlowercase)

* [zen::common::shell::color::randomizer](#zencommonshellcolorrandomizer)

* [zen::common::make::install](#zencommonmakeinstall)

* [zen::common::scons::install](#zencommonsconsinstall)

* [zen::common::validate](#zencommonvalidate)


## Environment Functions

The following functions are used for environment variable management.

### zen::common::environment::get::variable

This function fetches the value of a specified environment variable, displaying an error if not found.

#### Arguments

* **$1** (string): Name of the environment variable to retrieve.

#### Exit codes

* **0**: if the variable is found.
* **1**: if the variable is not found.

#### Output on stdout

* Value of the specified environment variable.

### zen::common::environment::set::variable

This function exports a given variable and its value, appending it to the root user's .bash_profile if it's not already present.
It ensures that the variable will be set and available in future shell sessions for the root user.
The function splits the input into a variable name and value, then checks and appends the export statement to .bash_profile.

> [!NOTE]
> If the variable is already exported in the .bash_profile, this function does not duplicate it.

> [!IMPORTANT]
> Only use this function for variables that should persist across sessions for the root user.

#### Arguments

* **$1** (string): The variable assignment in 'NAME=VALUE' format.

#### Output on stdout

* None.

### zen::common::bashrc::append

This function appends specified lines to the .bashrc file for a specified user, ensuring that each line is present
in future shell sessions. It is useful for adding custom environment variables or aliases to the shell environment.

#### Arguments

* **$1** (string): Name of the array containing lines to be appended to the .bashrc file.
* **$2** (string): (optional) Username whose .bashrc file will be modified. Defaults to the current user if not provided.

#### Exit codes

* **0**: on successful appending.
* **1**: on failure.

#### Output on stdout

* None.

## Setting Functions

The following functions are used for managing application settings.

### zen::common::setting::load

This function loads various settings from the database and populates a global associative array with these settings.
The function is crucial for configuring the application based on database-stored preferences.

#### Exit codes

* **0**: on successful loading.
* **1**: on failure.

### zen::common::dashboard::log

This function logs given messages to a file, which can be used for displaying logs on a dashboard.
It creates and manages the log file, ensuring it's owned by the appropriate user.

#### Arguments

* **$1** (string): Message to be logged.

#### Output on stdout

* None.

## String/Shell extra Functions

The following functions are used for shell operations.

### zen::common::capitalize::first

This function transforms a string by capitalizing its first letter, useful for formatting display text.

> [!TIP]
> Use this function to format user-visible strings consistently.

#### Arguments

* **$1** (string): String to be capitalized.

#### Output on stdout

* Transformed string with the first letter capitalized.

### zen::common::lowercase

This function converts a given string to lowercase, ensuring consistent formatting for display text.

#### Arguments

* **$1** (string): String to be converted to lowercase.

#### Output on stdout

* Transformed string in lowercase.

### zen::common::shell::color::randomizer

This function randomly selects a color code for styling shell outputs, adding visual diversity to command line interfaces.

> [!NOTE]
> This function is useful for creating visually distinct outputs.

#### Output on stdout

* Random color code.

### zen::common::make::install

This function handles the compilation and installation of a project that uses the make build system.
It utilizes all available processors to speed up the compilation and allows specification of additional make arguments and installation directory.

> [!NOTE]
> This function optimizes build speed by using parallel build options based on the number of available processors.

#### Arguments

* **$1** (string): Source directory where the makefile is located and where the build process should occur.
* **$2** (string): Installation directory where the built project should be installed. This is optional and, if specified, is used in the `make install` command with the DESTDIR prefix.
* **$3** (string): Additional arguments to pass to the make command during the build process (optional).
* **$4** (string): Additional arguments for the make install command, allowing further customization of the install process (optional).

#### Exit codes

* **0**: on successful build and installation.
* **1**: on failure during either the build or install step.

#### Output on stdout

* Information and status updates about each step of the build and installation process.

## Building tools Functions

The following functions are used for building tools.

### zen::common::scons::install

This function handles the configuration, building, and installation of a project that utilizes scons as its build system.
It supports building in debug mode and allows specifying a custom installation directory.

> [!NOTE]
> This function assumes the presence of scons in the system and relies on proper configuration of the project for scons.

#### Arguments

* **$1** (string): Source directory of the project to be built.
* **$2** (string): Installation directory where the project should be installed (optional).
* **$3** (string): Debug build flag; if set to 'true', the project will be built in debug mode (optional).

#### Exit codes

* **0**: on successful execution.
* **1**: on failure at any step (configuration, building, or installation).

#### Output on stdout

* Information about the process steps and their success or failure.

### zen::common::validate

: Validates user input based on a specific filter.

#### Examples

```bash
# returns 0
zen::common::validate "email" "contact@me.com"
```

```bash
# returns 1
zen::common::validate "email" "contact@me"
```

```bash
# returns 0
zen::common::validate "url" "https://example.com"
```

```bash
# returns 1
zen::common::validate "url" "example.com"
```

```bash
# returns 0
zen::common::validate "database" "data"
```

```bash
# returns 1
zen::common::validate "database" "$data%"
```

```bash
# returns 0
zen::common::validate "ipv4" "192.168.1.1"
```

```bash
# returns 1
zen::common::validate "ipv4" "256.256.256.256"
```

```bash
# returns 0
zen::common::validate "ipv6" "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
```

```bash
# returns 1
zen::common::validate "ipv6" "2001:0db8:85a3::8a2e:0370:7334"
```

```bash
# returns 0
zen::common::validate "mac" "00:1A:2B:3C:4D:5E"
```

```bash
# returns 1
zen::common::validate "mac" "00:1A:2B:3C:4D:5E:6F"
```

```bash
# returns 0
zen::common::validate "hostname" "example-hostname"
```

```bash
# returns 1
zen::common::validate "hostname" "example_hostname"
```

```bash
# returns 0
zen::common::validate "fqdn" "example.com"
```

```bash
# returns 1
zen::common::validate "fqdn" "example..com"
```

```bash
# returns 0
zen::common::validate "domain" "example.com"
```

```bash
# returns 1
zen::common::validate "domain" "example"
```

```bash
# returns 0
zen::common::validate "group" "media"
```

```bash
# returns 1
zen::common::validate "group" "unsupported_group"
```

```bash
# returns 0
zen::common::validate "github" "https://github.com/MediaEase/shdoc"
```

```bash
# returns 0
zen::common::validate "github" "MediaEase/shdoc"
```

```bash
# returns 0
zen::common::validate "docs" "https://example.com/docs"
```

```bash
# returns 1
zen::common::validate "docs" "https://example.com/documentation"
```

```bash
# returns 0
zen::common::validate "port_range" "8000-9000"
```

```bash
# returns 1
zen::common::validate "port_range" "8000:9000"
```

```bash
# returns 0
zen::common::validate "numeric" "12345"
```

```bash
# returns 1
zen::common::validate "numeric" "12345a"
```

```bash
# returns 0
zen::common::validate "password" "password1234"
```

```bash
# returns 1
zen::common::validate "password" "passw'~ord"
```

```bash
# returns 0
zen::common::validate "username" "user123"
```

```bash
# returns 1
zen::common::validate "username" "us"
```

```bash
# returns 0
zen::common::validate "quota" "100GB"
```

```bash
# returns 0
zen::common::validate "quota" "1000MB"
```

```bash
# returns 0
zen::common::validate "quota" "1TB"
```

```bash
# returns 1
zen::common::validate "quota" "10KB"
```

```bash
# returns 0
zen::common::validate "version" "1.0.0"
```

```bash
# returns 0
zen::common::validate "version" "1.0.0-alpha.1"
```

```bash
# returns 0
zen::common::validate "version" "1.0.0-beta"
```

```bash
# returns 0
zen::common::validate "version" "1.0.0-rc.1"
```

```bash
# returns 1
zen::common::validate "version" "1.0.0-rc.1.1"
```

```bash
# returns 1
zen::common::validate "version" "Best Version Ever"
```

#### Exit codes

* 0: Successful execution, valid input.
* 1: Invalid input.

---
This file was auto-generated by [shdoc](https://github.com/MediaEase/shdoc)
