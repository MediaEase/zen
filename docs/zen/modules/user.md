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

### zen::user::create

Creates a new system user with specified attributes.

#### Arguments

* **$1** (string): The username for the new user.
* **$2** (string): The password for the new user.
* **$3** (string): Indicates if the user should have admin privileges ('true' or 'false').

### zen::user::groups::upgrade

Adds a user to a specified system group.

#### Arguments

* **$1** (string): The username of the user to add to the group.
* **$2** (string): The name of the group to which the user should be added.

### zen::user::groups::create_groups

Creates default system groups for application usage.

### zen::user::check

Checks if the currently loaded user is a valid MediaEase user.

### zen::user::is::admin

Checks if the currently loaded user is an administrator.

### zen::multi::check::id

Retrieves the ID of a specified user from the system.

#### Arguments

* **$1** (string): The username for which to retrieve the ID.

### zen::user::load

Loads a specified user's data into a globally accessible associative array.

#### Arguments

* **$1** (string): The username of the user to load.

### zen::user::ban

Bans a user either permanently or for a specified duration.

#### Arguments

* **$1** (string): The username to ban.
* **$2** (string): Optional duration in days for the ban.

## Password Management

Generates a random password of a specified length.

### zen::user::password::generate

Generates a random password of a specified length.

#### Arguments

* **$1** (int): The length of the password to generate.

### zen::user::password::set

Sets a password for a specified user.

#### Arguments

* **$1** (string): The username of the user for whom to set the password.
* **$2** (string): The password to set for the user.

