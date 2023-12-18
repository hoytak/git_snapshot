# Git for Incremental Snapshots

Use these scripts to snapshot your home directory or any other directory evolves over time.  Any snapshot can be mounted later for read-only viewing.  With git-xet, all binary content is deduped within and across snapshots, allowing the data to be stored very efficiently. 

# Why Git Xet? 

There are a number of tools out that allow git to work with large data files.  The open source [git-xet plugin](https://github.com/xetdata/xet-core) is the only one that does full content-based deduplication of all data, binary and text.  This means that identical content between differing files is only stored once, making it nice for incremental backups.   Furthermore, it does not require any per-file configuration, so it can be set up once for the repo and require no further configuration.

And full disclosure: I am a developer on the git-xet team, and this has been a fun side project to see how feasible this is.

# Why Git?

Why not? 

# Getting started

1. Install the open source [git-xet extension](https://github.com/xetdata/xet-core).  Binaries are available from [here](https://github.com/xetdata/xet-tools/releases).  After downloading, run `git xet install` to install the proper config settings.

2. Create a repo to use as the backup.
   
   - Local: 
   
     Create a local git repository, ideally on a NAS or external disk, and enable the 
     git-xet plugin using 
     
     ```sh
     mkdir -p <repo_dir> && cd <repo_dir> && git init --bare && git xet init
     ```

   - GitHub: 
   
     Create a new private repo on GitHub to use as the backup.  Then, install the 
     [GitHub App](https://about.xethub.com/product/integrations/github) and tell it to 
     configure your repo for git-xet access.

   - XetHub: 
   
     After creating an account and logging in, create a new private repo on [XetHub](https://about.xethub.com).


3. Configure the data store and access. 

   - Local: 

     Choose a directory for the data store, ideally on a NAS or external disk.  You'll have to set 
     this configuration locally.

   - GitHub/XetHub, data stored on XetHub:  
   
     This requires an account at [xethub.com](xethub.com) and may incur data charges.  However, the upside is that all your data is deduped and stored in S3-backed storage, and with the [XetData GitHub App](https://github.com/apps/xetdata), all your files are viewable in your github repository. 
     
     Make sure you have an account at XetHub, then follow the authentication steps.

4. Edit [config.sh](config.sh) with the above settings.  If using the local data store, make sure you set `data_store` to `local://` followed by the folder referenced, e.g. `data_store=local:///nas/backups/data/`

# Usage

1. To create a snapshot, run 

   ```
   ./snapshot.sh
   ```

   This requires the remote repo and data store to be set in [config.sh](config.sh).  Otherwise, run 

   ```
   ./snapshot.sh --repo=<git repo> [--local-data-store=<data-directory>]
   ```

# Viewing

2. To mount a snapshot at a specific time, use 


   




