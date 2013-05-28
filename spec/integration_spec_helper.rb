require 'spec_helper'
require 'vcr'
require 'ansi/code'
require 'ansi/diff'

Chef::Config[:knife][:rackspace_api_username] = "#{ENV['OS_USERNAME']}"
Chef::Config[:knife][:rackspace_api_key] = "#{ENV['OS_PASSWORD']}"
Chef::Config[:knife][:ssl_verify_peer] = false
# Chef::Config[:knife][:rackspace_version] = "#{ENV['RS_VERSION']}"

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :excon
  c.configure_rspec_metadata!

  c.filter_sensitive_data('{RAX_USERNAME}') { Chef::Config[:knife][:rackspace_api_username] }
  c.filter_sensitive_data('{RAX_PASSWORD}') { Chef::Config[:knife][:rackspace_api_key] }
  c.filter_sensitive_data('{CDN-TENANT-NAME}') { ENV['RS_CDN_TENANT_NAME'] }
  c.filter_sensitive_data('{TENANT-ID}') { ENV['RS_TENANT_ID'] }

  c.before_record do |interaction|
    # Sensitive data
    filter_headers(interaction, /X-\w*-Token/, '{ONE-TIME-TOKEN}')

    # Transient data (trying to avoid unnecessary cassette churn)
    filter_headers(interaction, 'X-Compute-Request-Id', '{COMPUTE-REQUEST-ID}')
    filter_headers(interaction, 'X-Varnish', '{VARNISH-REQUEST-ID}')

    # Throw away build state - just makes server.wait_for loops really long during replay
    begin
      json = JSON.parse(interaction.response.body)
      if json['server']['status'] == 'BUILD'
        # Ignoring interaction because server is in BUILD state
        interaction.ignore!
      end
    rescue
    end
  end

  c.default_cassette_options = {
    # :record => :none,
    # Ignores cache busting parameters.
    :match_requests_on => [:host, :path]
  }
end

def filter_headers(interaction, pattern, placeholder)
  [interaction.request.headers, interaction.response.headers].each do | headers |
    sensitive_tokens = headers.select{|key| key.to_s.match(pattern)}
    sensitive_tokens.each do |key, value|
      headers[key] = placeholder
    end
  end
end

RSpec.configure do |c|
  # so we can use :vcr rather than :vcr => true;
  # in RSpec 3 this will no longer be necessary.
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

def clean_output(output)
  ANSI.unansi(output).gsub(/\s+$/,'')
end

RSpec::Matchers.define :match_output do |expected_output|
  match do |actual_output|
    clean_output(actual_output) == expected_output.strip
  end
  # Nice when it works, but has ANSI::Diff has some bugs that prevent it from showing any output
  failure_message_for_should do |actual_output|
    puts clean_output(actual_output)
    puts
    puts expected_output
    # output = clean_output actual_output
    # ANSI::Diff.new(output, expected_output)
  end
  description do
    'Compare actual and expected output, ignoring ansi color and trailing whitespace'
  end
end