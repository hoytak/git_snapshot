# Git for Incremental Snapshots

This script provides an easy way to use git to snapshot your home directory using git and git-xet.  Any given snapshot can then be mounted later for read-only viewing.   

(These instructions work for OSX and Linux currently.)

# Usage

1. Install the open source [git-xet extension](https://github.com/xetdata/xet-core).  Binaries are available from [here](https://github.com/xetdata/xet-tools/releases).  After downloading, run `git xet install` to install the proper config settings.
2. Ensure you have a backup directory with the same access as the directory you want to back up.  I am snapshotting my home directory `/hoytak/hoytak/`, so I created a directory `/home/hoytak_backup/` to use as the backup working directory.
3. Set up the backup repo and data storage endpoint (see below).
4. Download this repo, then edit the configuration settings in [setup.sh](setup.sh).
5. Run `./snapshot.sh` to create and save a snapshot.

# Data Endpoint Setup

Git Xet stores all the binary data and metadata at an endpoint.  All large files and binary data is automatically chunked and dedeplicated globally, so as files evolve or move, only new data is stored.  This makes it great for using git as a snapshot system for backups. 

## Setup option 1: Github repo with xethub data endpoint

This option is the easiest, but it requires an account at xethub.com and may incur data charges.  The upside is that all your data is deduped and stored in S3, and that with the [XetData GitHub App](https://github.com/apps/xetdata), all your files are viewable in your github account. 

- Create a github repo for your dat. 
- Install the [GitHub App](https://github.com/apps/xetdata), and enable the git xet extension on your repository.

## Setup option 2: Github or Local repo with NAS endpoint

If you have a NAS client that exposes an NFS share, this option is free.  All the content gets backed up to your NAS, with all the data deduped. 

1. mount a nas share at a specific location, e.g. `/nas`.
2. If not using github, create a new xet-enabled git repo: 

   ```
   cd /nas && mkdir backup_repo.git && cd backup_repo.git/
   git init --bare
   git xet init
   ```
3. Create a directory for the content address store, e.g. `/nas/cas`. 
4. In `setup.sh`, uncomment and configure the environment variable for local usage:
   ``` 
   export XET_CAS_SERVER=local:///nas/cas
   ```
   




