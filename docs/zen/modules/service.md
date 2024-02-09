# modules/service.sh

## Overview

Contains a library of functions used in the MediaEase Project for managing services.

## Index

* [zen::service::generate](#zenservicegenerate)
* [zen::service::manage](#zenservicemanage)
* [zen::service::build::add_entry](#zenservicebuildaddentry)
* [zen::service::validate](#zenservicevalidate)

### zen::service::generate

Generates a systemd service file for an application.

#### Arguments

* **$1** (string): The name of the application.
* **$2** (bool): Flag indicating if the service is for multiple users.
* **$3** (bool): Flag indicating if the service should be started immediately (optional).

#### Output on stdout

* Creates a systemd service file for the application.

### zen::service::manage

Manages the state of a systemd service.

#### Arguments

* **$1** (string): The action to perform (start, stop, restart, enable, disable, status).
* **$2** (string): The name of the service to manage.

#### Output on stdout

* Performs the specified action on the systemd service.

### zen::service::build::add_entry

Adds an entry to the api_service associative array.

#### Arguments

* **$1** (string): The key of the entry to add.
* **$2** (string): The value of the entry.

#### Output on stdout

* Adds a key-value pair to the api_service associative array.

### zen::service::validate

Validates the api_service associative array and inserts data into the database.

#### Arguments

* **$1** (bool): Flag indicating if the service is a child service.
* **$2** (string): The sanitized name of the application.

#### Output on stdout

* Validates service configuration and inserts it into the database.

