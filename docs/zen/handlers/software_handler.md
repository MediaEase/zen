# handler/software_handler.sh

## Overview

A handler for software management commands.

## Index

* [zen::software::handle_action](#zensoftwarehandleaction)
* [zen::args::process](#zenargsprocess)

### zen::software::handle_action

Handles the specified action for the given software.

#### Example

```bash
zen::software::handle_action "add" "jason" "radarr"
```

#### Arguments

* **$1** (string): The action to be performed (add, remove, backup, update, reset).
* **$2** (string): The username associated with the application.
* **$3** (string): The name of the application.

#### Output on stdout

* Executes the appropriate action for the specified software.

### zen::args::process

Processes command-line arguments for software management commands.

#### Example

```bash
zen::args::process "$@"
```

#### Arguments

* **...** (array): Command-line arguments.

#### Output on stdout

* Parses action, username, application name, and options from the arguments.
  Calls zen::software::handle_action with the parsed arguments.

