current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
#node_name                "knife-rackspace"
#client_key               "#{current_dir}/knife-rackspace.pem"
#validation_client_name   "knife-rackspace-validator"
#validation_key           "#{current_dir}/knife-rackspace-validator.pem"
#chef_server_url          "https://api.opscode.com/organizations/knife-rackspace"
#cache_type               'basicfile'
#cache_options( :path => "#{ENV['home']}/.chef/checksums" )
#cookbook_path            ["#{current_dir}/../cookbooks"]

knife[:rackspace_api_username] = "#{ENV['OS_USERNAME']}"
knife[:rackspace_api_key] = "#{ENV['OS_PASSWORD']}"

#https_proxy 'https://localhost:8888'
#knife[:ssl_verify_peer] = false

