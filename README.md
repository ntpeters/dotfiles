# dotfiles

My dotfiles repository.

## Setup

### Clone

This repo expects to be cloned to `~/.dotfiles`:

```sh
git clone git@github.com:ntpeters/dotfiles.git ~/.dotfiles
```

### Link

The dotfiles in this repo are intended to live in their own directory
(`~/.dotfiles`) and be linked into their expected locations.

> Linking files into place is currently managed by
[updot.py](https://github.com/ntpeters/updot).
> 
> **NOTE:** You shouldn't use it yourself, please don't even look at it.
> It's terrible, but I'm too lazy to migrate.

Download the updot script, then link everything into place with:

```sh
py updot.py --relink
```

### Additional Setup

#### Windows

On Windows there is an additional script that must be run to configure
settings, install apps, and link some Windows-specific configs into
place.

Execute the following in PowerShell as a non-admin user:

```pwsh
${Env:UserProfile}\.dotfiles\setup.ps1
```
