# Puppet Catalog Metrics

This is a simple script to collect some catalog metrics from PuppetDB

The script will query PuppetDB using the Catalogs and Reports end points and calculate the average catalog size and average catalog compilation time.

You can then use these metrics to tune your PE infrastructure and calculate how many compile masters you require.

## Usage

Copy this script to your Puppet Master, make it executable and run it.

```bash
pe-201721-master vagrant # ./puppet_catalog_metrics.rb
Average catalog size: 497807 bytes
Average catalog compilation time: 6.00 seconds
```

## Limitations

Only tested on Puppet Enterprise. Should work with Puppet open source too.

Currently, the script assumes that it will be executed from the Puppet Master and that PuppetDB is running on the same host.

It can be used with split installations, just edit the line

```ruby
HOST       = `hostname -f`.chomp
```

## Contributing

This script was written in anger so there's a lot of room for improvement. Pull requests are welcome.
