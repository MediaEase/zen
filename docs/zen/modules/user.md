# modules/user.sh

## Overview

A library for internationalization functions.

## Index

* [zen::user::create](#zenusercreate)

* [zen::user::groups::upgrade](#zenusergroupsupgrade)

* [zen::user::groups::create_groups](#zenusergroupscreategroups)

* [zen::user::check](#zenusercheck)

* [zen::user::is::admin](#zenuserisadmin)

* [zen::multi::check::id](#zenmulticheckid)

* [zen::user::load](#zenuserload)

* [zen::user::ban](#zenuserban)

* [zen::user::password::generate](#zenuserpasswordgenerate)

* [zen::user::password::set](#zenuserpasswordset)

* [zen::user::remove](#zenuserremove)


## User Management Functions

Functions related to managing users in the system.

### zen::user::create

This function creates a new user with the given username, password, and admin status.
It adds users to the www-data group only if necessary, and grants sudo privileges for admin users.

> [!NOTE]
> Non-admin users have a restricted shell; admin users have sudo privileges without a password.

#### Arguments

* **$1** (string): The username for the new user.
* **$2** (string): The password for the new user.
* **$3** (string): Indicates if the user should have admin privileges ('true' or 'false').
* **$4** (string): (optional) Indicates if the user should be a system user ('true' or 'false').
* **$5** (string): (optional) Indicates if the user should be added to the www-data group ('true' or 'false').

### zen::user::groups::upgrade

This function adds a user to one of the predefined system groups.
The supported groups include sudo, media, download, streaming, and default.

> [!NOTE]
> Handles different groups including sudo, media, download, and streaming.

#### Arguments

* **$1** (string): The username of the user to add to the group.
* **$2** (string): The name of the group to which the user should be added.

### zen::user::groups::create_groups

This function creates predefined groups like media, download, streaming, and default for application usage.
It checks if the groups already exist before creating them.

> [!NOTE]
> Creates predefined groups like media, download, streaming, and default.

### zen::user::check

This function checks if the specified user exists and is a valid MediaEase user.
It relies on global variables for the username and the list of all system users.

### zen::user::is::admin

This function checks if the specified user, whose data is loaded into a global array, is an administrator.
It examines the user's roles to determine admin status.

> [!NOTE]
> User must be loaded with zen::user::load before calling this function.

### zen::multi::check::id

This function fetches the system ID of a specified user by querying the database.
It is part of the multi-user management functionality.

#### Arguments

* **$1** (string): The username for which to retrieve the ID.

### zen::user::load

This function queries the database for a user's data and loads it into a globally accessible associative array named 'user'.
It prepares the user's data for further processing in other functions.

> [!NOTE]
> Queries the database and populates the 'user' array with the user's data.

> [!NOTE]
> Queries the database and populates the 'user' array with the user's data.

> [!WARNING]
> Ensure the user exists before calling this function.

#### Arguments

* **$1** (string): The username of the user to load.

### zen::user::ban

This function bans a specified user, either permanently or for a given duration.
It updates the user's status in the database to reflect the ban.

> [!NOTE]
> Duration is in days; omit for a permanent ban.

#### Arguments

* **$1** (string): The username to ban.
* **$2** (string): Optional duration in days for the ban.

## Password Management

Functions related to managing user passwords.

### zen::user::password::generate

This function generates a secure, random password of the specified length using system utilities.
It is used for creating default passwords for new users.

> [!NOTE]
> Uses /dev/urandom for secure password generation.

#### Arguments

* **$1** (int): The length of the password to generate.

### zen::user::password::set

This function sets a password for a given user.
It updates the system's password record and adds the password to the system's HTTP authentication file.

> [!NOTE]
> The password is also added to the system's htpasswd file for HTTP authentication.

#### Arguments

* **$1** (string): The username of the user for whom to set the password.
* **$2** (string): The password to set for the user.

### zen::user::remove

Removes an existing user and their associated home directory and files if requested.
This function removes a specified user from the system and optionally deletes their home directory and associated files.

> [!NOTE]
> Ensure the username is valid, as this action cannot be undone.

#### Arguments

* **$1** (string): The username of the user to be removed.
* **$2** (bool): (optional) Indicates whether the user's home directory should also be removed. Defaults to 'true'.

---
This file was auto-generated by [shdoc](https://github.com/MediaEase/shdoc)
