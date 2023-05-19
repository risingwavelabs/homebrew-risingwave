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
