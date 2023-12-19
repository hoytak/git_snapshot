# Git for Incremental Backup

Create a snapshot of any directory, including your home folder, and commit it to a git repository.  Any snapshot can then be mounted later for read-only browsing.  

These scripts use git with the open source [git-xet plugin](https://github.com/xetdata/xet-core).  Using git-xet, all binary content is deduped within and across snapshots, allowing the data to be stored very efficiently.

# Table of Contents

* [Usage](#usage)
  * [Installation](#installation)
  * [Setup](#setup)
    * [Setup: Local](#setup-local)
    * [Setup: Github](#setup-github)
    * [Setup: XetHub](#setup-xethub)
  * [Creating Snapshots](#creating-snapshots)
  * [Browsing Snapshots](#browsing-snapshots)
* [Design Philosophy](#design-philosophy)
  * [Why Git?](#why-git)
  * [Why Git-Xet?](#why-git-xet)
* [Optional: XetHub Account Setup](#optional-xethub-account-setup)
  * [Authentication](#authentication)
    * [Command Line](#command-line)
    * [Environment Variables](#environment-variables)
* [License](#license)

# Usage

## Installation

1. Clone this repository.  To get this to run reliably, you will need to edit the [config.sh](config.sh) file with your settings. 

2. Install the [git-xet extension](https://github.com/xetdata/xet-core).  Binaries are available from [here](https://github.com/xetdata/xet-tools/releases).  

3. Run `git xet install` to install the proper config settings.

## Setup

Here are three ways to configure 

### Setup: Local

This setup assumes that you have a external drive or NAS mounted at a specific folder.  

1. Create the Repo.  Create a git repository on the nas drive and enable the git-xet plugin using 
     
  ```sh
  repo_directory="/NAS/backup/snapshot-repo.git" # Change this to your directory
  mkdir -p "$repo_directory" && cd "$repo_directory" && git init --bare && git xet init
  ``` 

2. Create the Data Store.   Simply create a directory to use as the data store.

  ```sh
  data_directory="/NAS/backup/data" # Change this to your directory
  mkdir -p "$data_directory" 
  ```

3. Edit the settings in [config.sh](config.sh) to add these directories:

  ```sh
  git_repo="/NAS/backup/snapshot-repo.git"
  local_data_store="/NAS/backup/data"
  ```

### Setup: Github

1. Create a new repo on GitHub to use as the backup.

2. Install the [XetHub App for github](https://about.xethub.com/product/integrations/github) and select your repoository for git-xet configuration.

3. Configure the Data Store.

    - Managed: To store your data in the fully managed [XetHub](https://about.xethub.com) service, follow the instructions in [XetHub Account Setup](#optional-xethub-account-setup).  No other configuration is needed. 

    - Local: Follow the instructions for the data store [above](#setup-local). 

4. Edit the settings in [config.sh](config.sh) to add this information:

  ```sh
  git_repo="git@github.com:username/backup-repo.git"
  ```

  If using a local data store, also add: `local_data_store="<backup-dir>"`, otherwise leave that variable empty.

### Setup: XetHub

The XetHub service is similar to github, but all binary data is conveniently accessible through the web interface.

1. Setup an account by following the instructions in [XetHub Account Setup](#optional-xethub-account-setup).  

2. Create a repository and copy the appropriate URL (e.g. `xet@xethub.com:username/backup-repo.git`).

3. Edit the settings in [config.sh](config.sh) to add this information:

  ```sh
  git_repo="xet@xethub.com:username/backup-repo.git"
  ``` 

## Creating Snapshots

1. Ensure the directory you want to snapshot is correct in [config.sh](config.sh).  The default is `snapshot_dir=$HOME` to snapshot your home folder.

2. To create a snapshot, simply run

  ```
  ./snapshot.sh
  ```

  This requires the remote repo and optionally the data store to be set in [config.sh](config.sh).

## Browsing Snapshots

To mount a snapshot at a specific time, use the provided script [mount.sh](mount.sh).  This is a 
convenience wrapper around git xet mount, which uses a local nfs server to mount the contents of a xet-enabled repository as a directory, with the file contents being downloaded and materialized lazily.

- To list commits available: 

  ```
  ./mount.sh --list
  ```

- To mount a specific commit: 

  ```
  ./mount.sh [COMMIT]
  ```
 
  The path for this commit is displayed at the end. 

- To unmount all snapshots:

  ```
  ./mount.sh --unmount 
  ```

# Design Philosophy

## Why Git?

Why not?  

But seriously, git historically has had issues handling enourmous, binary-heavy repositories that evolve over time.  However, the ecosystem is changing, and there are now several tools that make this feasible, including git-xet. 

## Why Git Xet?

There are a number of tools out that allow git to work with large data files.  I wrote this tool on top of [git-xet](https://github.com/xetdata/xet-core) for a few reasons:  

1. Binary Content Deduplication. Git-xet is currently the only open source git plugin that does full content-based deduplication across different commits and within the same commit.  Thus if two files share common content, the common content is only stored once, even if the full file content differs.  For more details on this, see our paper at [Git is for Data](https://www.cidrdb.org/cidr2023/papers/p43-low.pdf).

2. No per-file configuration.  Setup is once and done -- once a repo is set up, then all binary files and large text files pass through the git-xet plugin.

3. Easy browsing.  Any commit can be mounted locally as a read-only folder while lazily materializing the data.  The included `git xet mount` utility uses the [nfsserve](https://github.com/xetdata/nfsserve) package to mount a read-only view of any git commit, allowing previous snapshots to be browsed without materializing the contents.

4. Open source.  While the integration with [xethub](about.xethub.com) has many nice perks, git-xet can be used entirely locally.

Full disclosure:  I am a developer on the team building git-xet, so I'm biased.  However, this tool was a great way to ensure that git can easily handle terabytes of data with minimal pain, which was our goal in building git-xet.  Please let me know if you have any feedback, and please [file issues](https://github.com/xetdata/xet-core/issues) if you have any problems. 

# Optional: XetHub Account Setup

The use of the fully managed [XetHub](about.xethub.com) service provides many perks, including reliable data storage and seamless minimal-configuration integration with git.

## Authentication

Signup on [XetHub](https://xethub.com/user/sign_up) and obtain a username and personal access token. You should save this token for later use, or go to https://xethub.com/user/settings/pat to create a new token. 

There are two ways to authenticate with XetHub:

### Command Line

Run the command given when you create your personal access token:

```bash
git xet login -e <email> -u <username> -p <personal_access_token>
```
git xet login will write authentication information to `~/.xetconfig`

### Environment Variables

Environment variables may be sometimes more convenient:

```bash
export XET_USER_EMAIL = <email>
export XET_USER_NAME = <username>
export XET_USER_TOKEN = <personal_access_token>
```

# License

[MIT](LICENSE)
