# Contributing

## Table of Contents

- [Introduction](#introduction)
- [Configurations](#configurations)
- [Types of Contributions](#types-of-contributions)
- [Issues and Feature Requests](#issues-and-feature-requests)
- [How to Submit a Pull Request](#how-to-submit-a-pull-request)
- [Review Process](#review-process)
- [Branch Naming](#branch-naming)
- [Commit Message](#commit-message)


[Git-Flow]: https://github.com/nvie/gitflow/wiki/Installation
[better-commits]: https://github.com/Everduin94/better-commits#-installation
[GitHub Discussions]: https://github.com/MediaEase/MediaEase/discussions
[submitting an issue on GitHub]: https://github.com/MediaEase/MediaEase/issues
[Open a Pull Request]: https://github.com/MediaEase/MediaEase/compare?expand=1

## Introduction

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change. Please note we have a [code of conduct](CODE_OF_CONDUCT.md), please follow it in all your interactions with the project. We use some tools to help us maintain our project standards, such as [better-commits] and [Git-Flow]. **Please note that better-commits is already initialized. So you don't have to initialize it**.

## Development environment

Be sure to have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm#using-a-node-version-manager-to-install-nodejs-and-npm) installed on your computer.

Then, you can clone the repo :

 ```bash
 git clone https://github.com/MediaEase/HarmonyUI
 cd HarmonyUI
 ``` 

> on Linux distributions (bash > 4.x)

You can automatically setup the development environment by running `bin/setup_repo.sh` .

This will setup donwload and setup Git-Flow.

> on Windows :

Install [git](https://community.chocolatey.org/packages/git) and [npm](https://community.chocolatey.org/packages/nodejs.install).

Then, you  can install [better-commits].

You don't need to install [Git-Flow] as it's included with the git package.
## Configurations

### Better-Commits

> See [configuration](https://github.com/MediaEase/HarmonyUI/blob/main/.better-commits.json)

### Git-Flow

> Run `git-flow init -d -f`

## Types of Contributions

### Bugfix

A bugfix is a change meant to fix a specific issue in the codebase. These are generally small changes that target very specific issues. Bugfix branches should be named `bugfix/your-bugfix-name`.

### Hotfix

A hotfix is a type of bugfix, but it's urgent and should be applied as soon as possible. These are critical fixes that often address issues affecting the system's stability or security. Hotfix branches should be named `hotfix/your-hotfix-name`.

### Feature

A feature is a new addition to the codebase that provides new functionality or improves existing features. These are generally larger changes and can include anything from new methods to full modules. Feature branches should be named `feature/your-feature-name`.

## Issues and Feature Requests

You've found a bug in the source code, a mistake in the documentation, or maybe you'd like a new feature? Take a look at [GitHub Discussions] to see if it's already being discussed. You can help us by [submitting an issue on GitHub]. Before you create an issue, make sure to search the issue archive -- your issue may have already been addressed!

## How to Submit a Pull Request

### For Features

1. Create your feature branch: `git-flow feature start MYFEATURE`.
2. Push to the branch: `git push`.
3. Once your feature is done: `git-flow feature finish MYFEATURE`.
4. [Open a Pull Request] to the beta branch.
5. If your changes are stable enough, they will be merged into the main branch after successful beta testing.

### For Bugfixes/Hotfixes

1. Create your fix branch: `git-flow hotfix start bug-i-want-to-fix`.
2. Commit your changes by running: `better-commit`.
3. Push to the branch: `git push`.
4. Once your fix is done: `git-flow hotfix finish bug-i-want-to-fix`.
5. [Open a Pull Request] to the main branch.

## Review Process

1. **Automated Checks**: Initially, automated checks for code style, security vulnerabilities, and other issues will be run. Your PR must pass these checks before it can be merged.
2. **Code Review**: A core contributor will review your changes to ensure they meet the project's coding and documentation standards.
3. **Feedback Loop**: If changes are requested, you are expected to address these comments, after which the pull request will be reviewed again.
4. **Merge**: Once your pull request has been approved and passed all checks, it will be merged into the appropriate branch.

## Branch Naming

We follow a specific naming convention for branches to keep things organized:

- **Feature Branches**: `feature/your-feature-name`
- **Bugfix Branches**: `bugfix/your-bugfix-name`
- **Hotfix Branches**: `hotfix/your-hotfix-name`

> see [types of contributions](#types-of-contributions)

## Commit Message

We use `better-commits` for commit message formatting. This tool will guide you through a series of prompts to generate a well-formatted commit message.

1. **Type**: You'll be prompted to select the type of change you're committing (e.g., feat, fix, chore, docs, style, refactor, perf, test).
2. **Scope**: You'll then be asked to specify the scope of the change. This is optional. You can select `none` if you don't know what to choose!
3. **Description**: Finally, you'll be asked to provide a short (under 100 characters) description of the change.

Example commit message generated by `better-commits`:
> fix: button behavior
