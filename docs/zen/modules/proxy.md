# modules/proxy.sh

## Overview

Contains a library of functions used in the MediaEase Project for managing proxies.

## Index

* [zen::proxy::generate](#zenproxygenerate)
* [zen::proxy::add_directive](#zenproxyadddirective)
* [zen::proxy::remove](#zenproxyremove)

### zen::proxy::generate

Generates a Caddy proxy configuration file for an application.

#### Arguments

* **$1** (string): The name of the application.
* **$2** (number): The port on which the application is running.
* **$3** (string): The base URL for routing to the application.

#### Output on stdout

* Creates or overwrites a Caddy configuration file.

### zen::proxy::add_directive

Adds a directive to an application's Caddy proxy configuration.

#### Arguments

* **$1** (string): The name of the application.
* **$2** (string): The username associated with the application (multi-user mode).
* **$3** (string): The directive to be added to the proxy configuration.

#### Output on stdout

* Appends the directive to the application's proxy configuration file.

### zen::proxy::remove

Removes the proxy configuration file for a specified application.

#### Arguments

* **$1** (string): The name of the application.
* **$2** (string): The username associated with the application (multi-user mode).

#### Output on stdout

* Deletes the Caddy configuration file for the specified application.

