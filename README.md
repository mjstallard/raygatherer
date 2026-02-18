# Raygatherer

This is a CLI to interact with [Rayhunter](https://github.com/EFForg/rayhunter/). It was built with the intent of giving myself the ability to automate alerting and recording management on a Rayhunter that is not-mobile (ie., it is plugged in 24/7 in my attic). If you too wish to script or otherwise automate using your Rayhunter, you might find this to be helpful!

**Important:** This is a personal side-project, and has no affiliation with or endorsement from the Rayhunter project, or the EFF. It is entirely unofficial, and without warranty.

## What It Does

Currently implemented:

- alerts from live analysis, with severity-based exit codes
- recording list/start/stop/delete/download
- system stats
- analysis queue status and triggering analysis runs
- config show/set/test-notification
- JSON output mode for scriptable commands
- optional basic auth and config file support

## Installation

### Ruby version

`raygatherer` requires Ruby `>= 3.1.0`.

### Install from this repo

```bash
bundle install
make build
make install
```

Or install directly with RubyGems:

```bash
gem build raygatherer.gemspec
gem install ./raygatherer-*.gem
```

## Quick Start

Check CLI help:

```bash
raygatherer --help
```

Check live alerts:

```bash
raygatherer --host http://rayhunter.local alerts
```

Check live alerts as JSON:

```bash
raygatherer --host http://rayhunter.local --json alerts
```

List recordings:

```bash
raygatherer --host http://rayhunter.local recording list
```

Download a recording:

```bash
raygatherer --host http://rayhunter.local recording download 1738950000
```

Show analysis queue status:

```bash
raygatherer --host http://rayhunter.local analysis status
```

Show system stats:

```bash
raygatherer --host http://rayhunter.local stats
```

## Global Flags

These can be used with any command:

- `--host HOST` (required unless provided in config file)
- `--basic-auth-user USER`
- `--basic-auth-password PASS`
- `--verbose`
- `--json` (only applies to commands that support JSON output)

## Configuration File

By default, config is loaded from:

- `~/.config/raygatherer/config.yml`
- or `$XDG_CONFIG_HOME/raygatherer/config.yml` if `XDG_CONFIG_HOME` is set

Supported keys:

- `host`
- `basic_auth_user`
- `basic_auth_password`
- `json`
- `verbose`

CLI flags always override config values.

Example:

```yaml
host: http://rayhunter.local
basic_auth_user: admin
basic_auth_password: replace-me
json: false
verbose: false
```

## Commands

Main commands:

- `alerts`
- `recording list`
- `recording download <name> [--qmdl|--pcap|--zip] [--download-dir DIR|--save-as PATH]`
- `recording delete <name>`
- `recording stop`
- `recording start`
- `analysis status`
- `analysis run [NAME|--all]`
- `config show`
- `config set` (reads JSON from stdin)
- `config test-notification`
- `stats`

For command-specific help:

```bash
raygatherer COMMAND --help
```

Examples:

```bash
raygatherer alerts --help
raygatherer recording download --help
raygatherer analysis run --help
```

## Alerts Exit Codes

`alerts` returns severity-based codes so shell scripts can react:

- `0`: no alerts
- `1`: error
- `10`: low severity alert
- `11`: medium severity alert
- `12`: high severity alert

Example:

```bash
raygatherer --host http://rayhunter.local alerts
code=$?
[ "$code" -ge 11 ] && echo "medium or high alert"
```

## JSON Output

Commands that support `--json` return machine-readable output to `stdout`. This is intended for `jq` and/or scripts.

Example:

```bash
raygatherer --host http://rayhunter.local --json config show | jq '.analyzers'
```

## Development

Install dependencies:

```bash
bundle install
```

Run tests:

```bash
make test
```

Run linter:

```bash
make lint
```

Build gem:

```bash
make build
```

## Security Notes

- This tool can send credentials over plaintext via HTTP if you point it at `http://...`.
- Config files may contain credentials. Restrict permissions appropriately.
- This is an unofficial tool. Verify behavior in your environment before relying on it.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Raygatherer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mjstallard/raygatherer/blob/master/CODE_OF_CONDUCT.md).
