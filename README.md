# homebrew-risingwave

Homebrew tap for [RisingWave](https://github.com/risingwavelabs/risingwave), a distributed SQL database for stream processing.

## Installation

Install [Homebrew](https://brew.sh/) first. Then, tap this repository:

```shell
$ brew tap risingwavelabs/risingwave
```

To install the latest release version:

```shell
$ brew install risingwave
```

Or, to install the latest development version:

```shell
$ brew install risingwave --HEAD
```

You can now start the RisingWave playground and connect to it with the Postgres interactive terminal `psql`:

```shell
$ risingwave playground

# In another terminal...
$ psql -h localhost -p 4566 -d dev -U root
```

### Install old versions

```shell
$ brew install risingwave@1.2

# If you haven't installed other versions, it's available as `risingwave`
$ risingwave --version
# If you have installed other versions, you can find it with `brew --prefix`
$ $(brew --prefix risingwave@1.2)/bin/risingwave --version
```

## Contributing

Bump formula version:

```
brew bump-formula-pr risingwave --url https://github.com/risingwavelabs/risingwave/archive/refs/tags/v<x.y.z>.tar.gz
```

At the same time, copy the old formula to `risingwave@<x.y>` and change its class name to `RisingwaveAT<xy>`, so that the old version can still be installed.
