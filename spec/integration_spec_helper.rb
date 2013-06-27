require 'spec_helper'
require 'vcr'
require 'ansi/code'
require 'ansi/diff'
require 'fog'
require 'knife/dsl'
require 'vcr/filters/network'

Chef::Config[:knife][:rackspace_api_username] = "#{ENV['OS_USERNAME']}"
Chef::Config[:knife][:rackspace_api_key] = "#{ENV['OS_PASSWORD']}"
Chef::Config[:knife][:ssl_verify_peer] = false
# Chef::Config[:knife][:rackspace_version] = "#{ENV['RS_VERSION']}"

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :excon
  c.configure_rspec_metadata!

  # Sensitive data
  c.filter_sensitive_data('_RAX_USERNAME_') { Chef::Config[:knife][:rackspace_api_username] }
  c.filter_sensitive_data('_RAX_PASSWORD_') { Chef::Config[:knife][:rackspace_api_key] }
  c.filter_sensitive_data('_CDN-TENANT-NAME_') { ENV['RS_CDN_TENANT_NAME'] }
  c.filter_sensitive_data('000000') { ENV['RS_TENANT_ID'] }

  c.before_record do |interaction|
    # Sensitive data
    filter_headers(interaction, /X-\w*-Token/, '_ONE-TIME-TOKEN_')

    # Transient data (trying to avoid unnecessary cassette churn)
    filter_headers(interaction, 'X-Compute-Request-Id', '_COMPUTE-REQUEST-ID_')
    filter_headers(interaction, 'X-Varnish', '_VARNISH-REQUEST-ID_')

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

  c.before_playback do | interaction |
    interaction.filter!('_TENANT-ID_', '0000000')
  end

  c.default_cassette_options = {
    # :record => :none,
    # Ignores cache busting parameters.
    :match_requests_on => [:host, :path]
  }
  c.default_cassette_options.merge!({:record => :all}) if ENV['INTEGRATION_TESTS'] == 'live'
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
  output = ANSI.unansi(output)
  output.gsub!(/\s+$/,'')
  output.gsub!("\e[0G", '')
  output
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

def server_list
  stdout, stderr, status = knife_capture('rackspace server list')
  status == 0 ? stdout : stderr
end

def capture_instance_data(stdout, labels = {})
  result = {}
  labels.each do | key, label |
    result[key] = clean_output(stdout).match(/^#{label}: (.*)$/)[1]
  end
  result
end

# Ideally this belongs in knife-dsl, but it causes a scoping conflict with knife.rb.
# See https://github.com/chef-workflow/knife-dsl/issues/2
def knife_capture(command, args=[], input=nil)
  null = Gem.win_platform? ? File.open('NUL:', 'r') : File.open('/dev/null', 'r')

  if defined? Pry
    Pry.config.input = STDIN
    Pry.config.output = STDOUT
  end

  warn = $VERBOSE
  $VERBOSE = nil
  old_stderr, old_stdout, old_stdin = $stderr, $stdout, $stdin

  $stderr = StringIO.new('', 'r+')
  $stdout = StringIO.new('', 'r+')
  $stdin = input ? StringIO.new(input, 'r') : null
  $VERBOSE = warn

  status = Chef::Knife::DSL::Support.run_knife(command, args)
  return $stdout.string, $stderr.string, status
ensure
  warn = $VERBOSE
  $VERBOSE = nil
  $stderr = old_stderr
  $stdout = old_stdout
  $stdin = old_stdin
  $VERBOSE = warn
  null.close
end