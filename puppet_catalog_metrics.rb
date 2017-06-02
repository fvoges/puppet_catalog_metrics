#!/opt/puppetlabs/puppet/bin/ruby

require "net/https"
require "json"
require "uri"
require 'puppet'
require 'puppet/util/puppetdb'

Puppet.initialize_settings

class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end

  def mean
    sum / size
  end
end

# Logic to support PuppetDB API versions 3 and 4
# and the associated PuppetDB terminus interfaces
if Puppet::Util::Puppetdb.config.respond_to?("server_urls")
  uri = URI(Puppet::Util::Puppetdb.config.server_urls.first)
  HOST = uri.host
  PORT = uri.port
  catalog_endpoint = "/pdb/query/v4/catalogs"
  reports_endpoint = "/pdb/query/v4/reports?limit=100&offset=100"
else
  HOST = Puppet::Util::Puppetdb.server
  PORT = Puppet::Util::Puppetdb.port
  catalog_endpoint = "/v3/catalogs"
  reports_endpoint = "/v3/reports?limit=100&offset=100"
end

CACERT     = Puppet.settings['localcacert']
CLIENTCERT = Puppet.settings['hostcert']
CLIENTKEY  = Puppet.settings['hostprivkey']

def get_endpoint(url)
  uri  = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.cert = OpenSSL::X509::Certificate.new(File.read(CLIENTCERT))
  http.key  = OpenSSL::PKey::RSA.new(File.read(CLIENTKEY))
  http.ca_file = CACERT
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  data = JSON.parse(http.get(uri.request_uri).body)
end

host_url = "https://#{HOST}:#{PORT}"

status_endpoint = "#{host_url}/pdb/query/v4/catalogs"
status_output   = get_endpoint(status_endpoint)

catalog_sizes = []
status_output.each do | data |
  catalog_sizes << data['resources'].to_json.length
end

puts "Average catalog size: #{catalog_sizes.mean.to_int} bytes"

status_endpoint = "#{host_url}#{reports_endpoint}"
status_output   = get_endpoint(status_endpoint)

config_retrieval = []
status_output.each do | data |
   data['metrics']['data'].each do | data |
    if data['name'] == 'config_retrieval'
      config_retrieval << data['value']
    end
  end
end

puts "Average catalog compilation time: %.2f seconds" % config_retrieval.mean.to_int
