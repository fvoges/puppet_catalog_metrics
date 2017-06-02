#!/opt/puppetlabs/puppet/bin/ruby

require "net/https"
require "json"
require "uri"
require 'pp'

class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end

  def mean
    sum / size
  end
end

HOST       = `hostname -f`.chomp
PORT       = '8081'
CLIENTCERT = `hostname -f`.chomp

def get_endpoint(url)
  uri  = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.cert = OpenSSL::X509::Certificate.new(File.read("/etc/puppetlabs/puppet/ssl/certs/#{CLIENTCERT}.pem"))
  http.key  = OpenSSL::PKey::RSA.new(File.read("/etc/puppetlabs/puppet/ssl/private_keys/#{CLIENTCERT}.pem"))
  http.ca_file = '/etc/puppetlabs/puppet/ssl/certs/ca.pem'
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

status_endpoint = "#{host_url}/pdb/query/v4/reports"
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

