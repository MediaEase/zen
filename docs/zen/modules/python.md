# modules/python.sh

A library for managing Python virtual environments.

## Overview

Creates a Python virtual environment in the specified path.

## Index

* [zen::python::venv::create](#zenpythonvenvcreate)
* [zen::python::venv::build](#zenpythonvenvbuild)
* [zen::python::venv::remove](#zenpythonvenvremove)

### zen::python::venv::create

Creates a Python virtual environment in the specified path.

#### Arguments

* **$1** (string): The filesystem path where the virtual environment should be created.

### zen::python::venv::build

Installs Python packages in a virtual environment from a requirements file.

#### Arguments

* **$1** (string): The path to the virtual environment.
* **$2** (string): The path to the requirements file.
* **$3** (string): Space-separated string of packages to pre-install.

### zen::python::venv::remove

Removes a Python virtual environment from the filesystem.

#### Arguments

* **$1** (string): The filesystem path where the virtual environment should be removed.

