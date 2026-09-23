# GoAccess for Virtualmin

A Webmin/Virtualmin module for generating per-domain [GoAccess](https://goaccess.io/) HTML reports from Virtualmin access logs.

**Current version:** 1.4.4  
**Author:** Frank Beckmann, FNH media KG  
**Copyright:** © 2026 Frank Beckmann, FNH media KG

## Features

- Per-domain GoAccess reports for Virtualmin virtual servers
- Initial processing of rotated `access_log.N.gz` files followed by incremental updates
- Configurable update interval from 1 to 10,080 minutes
- Cron integration suitable for SysVinit systems
- Direct cron schedules where the configured interval can be represented exactly; timestamp-based scheduling for other intervals
- Configurable GoAccess log format
- Supported formats: `COMBINED`, `COMMON`, `VCOMBINED`, `CLOUDFRONT`, `CLOUDSTORAGE`, `AWSELB`, `SQUID`, `W3C`
- GoAccess installation/version check
- Domain name displayed in generated HTML reports
- Webmin/Virtualmin integration for configuration and report access

## Requirements

- Webmin / Virtualmin
- GoAccess **1.9.3 or newer**
- Perl
- cron
- Linux server with Virtualmin-managed domains

The module checks for GoAccess at:

- `/usr/bin/goaccess`
- `/usr/local/bin/goaccess`

The module was developed and tested in a Debian/Virtualmin environment using SysVinit. Compatibility with other distributions and init systems may vary.

## Installation

Download the current Webmin module package:

`goaccess-for-virtualmin-v1.4.4.wbm.gz`

Install it through Webmin's module installation interface.

After installation, verify that GoAccess 1.9.3 or newer is installed and that the cron daemon is running.

## Virtualmin log layout

For a Virtualmin domain administered by user `example`, the expected access log is typically:

```
/home/example/logs/access_log
```

Rotated compressed logs such as `access_log.1.gz` can be included during initial report generation.

## Scheduling

The configured update interval is between 1 and 10,080 minutes.

Where possible, the module writes a direct cron expression. Examples:

| Interval | Cron schedule |
| ---: | --- |
| 1 minute | `*/1 * * * *` |
| 5 minutes | `*/5 * * * *` |
| 60 minutes | `0 * * * *` |
| 120 minutes | `0 */2 * * *` |
| 360 minutes | `0 */6 * * *` |
| 720 minutes | `0 */12 * * *` |

Intervals that cannot be represented directly by the selected cron strategy, such as 61 or 90 minutes, use a once-per-minute cron dispatcher with a persisted timestamp to enforce the configured elapsed interval.

The cron definition is stored in:

```
/etc/cron.d/virtualmin-goaccess
```

## GoAccess log format

For standard Apache/Virtualmin access logs, `COMBINED` is the default.

Available formats are:

`COMBINED`, `COMMON`, `VCOMBINED`, `CLOUDFRONT`, `CLOUDSTORAGE`, `AWSELB`, `SQUID`, and `W3C`.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the version history.

## License

No license has been specified for this project yet.
