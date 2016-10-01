# Knife Rackspace

[![Gem Version](https://badge.fury.io/rb/knife-rackspace.svg)](https://rubygems.org/gems/knife-rackspace) [![Build Status](https://travis-ci.org/chef/knife-rackspace.svg?branch=master)](https://travis-ci.org/chef/knife-rackspace)

This is the official Chef Knife plugin for Rackspace Cloud Servers. This plugin gives knife the ability to create, bootstrap, and manage servers on all the regions for Rackspace Cloud Servers.

## Requirements

- Chef 12.0 higher
- Ruby 2.2.2 or higher

## Installation

Be sure you are running the latest version Chef. Versions earlier than 0.10.0 don't support plugins:

```
gem install chef
```

This plugin is distributed as a Ruby Gem. To install it, run:

```
gem install knife-rackspace
```

Depending on your system's configuration, you may need to run this command with root privileges.

Ensure only the latest knife-rackspace gem and no other is installed. In some cases having older versions of the gem will cause the new OpenStack functionality not to function properly. To check:

```
$> gem list --local | grep knife-rackspace
knife-rackspace (0.6.2, 0.5.12)
$> gem uninstall knife-rackspace -v "= 0.5.12"
Successfully uninstalled knife-rackspace-0.5.12
$> gem list --local | grep knife-rackspace
knife-rackspace (0.6.2)
```

## Configuration

In order to communicate with the Rackspace Cloud API you will have to tell Knife about your Username and API Key. The easiest way to accomplish this is to create some entries in your knife.rb file:

```ruby
knife[:rackspace_api_username] = "Your Rackspace API username"
knife[:rackspace_api_key] = "Your Rackspace API Key"
```

If your knife.rb file will be checked into a SCM system (ie readable by others) you may want to read the values from environment variables:

```ruby
knife[:rackspace_api_username] = "#{ENV['RACKSPACE_USERNAME']}"
knife[:rackspace_api_key] = "#{ENV['RACKSPACE_API_KEY']}"
```

You also have the option of passing your Rackspace API Username/Key into the individual knife subcommands using the **-A** (or **--rackspace-api-username**) **-K** (or **--rackspace-api-key**) command options

```
# provision a new 1GB Ubuntu 10.04 webserver
knife rackspace server create -I 112 -f 3 -A 'Your Rackspace API username' -K "Your Rackspace API Key" -r 'role[webserver]'
```

To select for the previous Rackspace API (aka 'v1'), you can use the **--rackspace-version v1** command option. 'v2' is the default, so if you're still using exclusively 'v1' you will probably want to add the following to your knife.rb:

```ruby
knife[:rackspace_version] = 'v1'
```

This plugin also has support for authenticating against an alternate API Auth URL. This is useful if you are a using a custom endpoint, here is an example of configuring your knife.rb:

```ruby
knife[:rackspace_auth_url] = "auth.my-custom-endpoint.com"
```

Different regions can be specified by using the `--rackspace-region` switch or using the `knife[:rackspace_region]` in the knife.rb file. Valid regions include :dfw, :ord, :lon, and :syd.

If you are behind a proxy you can specify it in the knife.rb file as follows:

```ruby
https_proxy https://PROXY_IP_ADDRESS:PORT
```

SSL certificate verification can be disabled by include the following in your knife.rb file:

```ruby
knife[:ssl_verify_peer] = false
```

Additionally the following options may be set in your knife.rb:

- flavor
- image
- distro
- template_file

## Knife Sub Commands

This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a --help flag

### knife rackspace server create

Provisions a new server in the Rackspace Cloud and then perform a Chef bootstrap (using the SSH protocol). The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists (provided by the provisioning). It is primarily intended for Chef Client systems that talk to a Chef server. By default the server is bootstrapped using the {chef-full}[<https://github.com/opscode/chef/blob/master/chef/lib/chef/knife/bootstrap/chef-full.erb>] template. This can be overridden using the **-d** or **--template-file** command options.

If no name is provided, nodes created with the v1 API are named after their instance ID, with the v2 API they are given a random 'rs-XXXXXXXXX' name.

Files can be injected onto the provisioned system using the **--file** switch. For example to inject my_script.sh into **/root/initialize.sh** you would use the following switch: **--file /root/initialize.sh=my_script.sh**

Note: You can only inject text files and the maximum destination path is 255 characters.

You may specify if want to manage your disk partitioning scheme with the **--rackspace-disk-config DISKCONFIG** option. If you bootstrap a `v2` node and leave this set to the default "AUTO", larger nodes take longer to bootstrap as it grows the disk from 10G to fill the full amount of local disk provided. This option allows you to pass "MANUAL" - which give you a node (in 1/2 to 1/4 of the time) and lets you manage ignoring, or formatting the rest of the disk on your own.

<http://docs.openstack.org/essex/openstack-compute/starter/content/Launch_and_manage_instances-d1e1885.html>

You may specify a custom network using the **--network [LABEL_OR_ID]** option. You can also remove the default internal ServiceNet and PublicNet networks by specifying the **--no-default-networks** switch. To use a network other than PublicNet for the bootstrap connection, specify the **--bootstrap-network LABEL** option.

Note: If you are using one of the `performanceX-X` machines, you need to put **-f** or **--flavor** in quotes.

#### Windows

Windows Servers require special treatment with the knife-rackspace gem.

First, you'll need to ensure you've installed the knife-windows gem. Installation instructions can be found over here: <http://docs.chef.io/plugin_knife_windows.html#install-this-plugin>

Secondly, you need to make sure that the image you're using has WinRM pre-configured. Unfortunately, none of the Rackspace Windows image have this done by default, so you'll need to run the following instructions in a Windows machine, then save a Snapshot to use when creating servers with knife rackspace: <http://docs.chef.io/plugin_knife_windows.html#requirements>

Thirdly, you must pass **--bootstrap-protocol winrm** and **--distro windows-chef-client-msi** parameters to the knife rackspace create command

If you have troubles, make sure you add the **-VV** switch for extra verbosity. The **--server-create-timeout** switch may also be your friend, as Windows machines take a long time to build compared to Linux ones.

### knife rackspace server delete

Deletes an existing server in the currently configured Rackspace Cloud account by the server/instance id. You can find the instance id by entering **knife rackspace server list**. Please note - this does not delete the associated node and client objects from the Chef server unless you pass the **-P** or **--purge** command option. Using the **--purge** option with v2 nodes will attempt to delete the node and client by the name of the node.

### knife rackspace server list

Outputs a list of all servers in the currently configured Rackspace Cloud account. Please note - this shows all instances associated with the account, some of which may not be currently managed by the Chef server. You may need to use the **--rackspace-version** and **--rackspace-region** options to see nodes in different Rackspace regions.

### knife rackspace flavor list

Outputs a list of all available flavors (available hardware configuration for a server) available to the currently configured Rackspace Cloud account. Each flavor has a unique combination of disk space, memory capacity and priority for CPU time. This data can be useful when choosing a flavor id to pass to the **knife rackspace server create** subcommand. You may need to use the **--rackspace-version** and **--rackspace-region** options to see nodes in different Rackspace regions.

### knife rackspace image list

Outputs a list of all available images available to the currently configured Rackspace Cloud account. An image is a collection of files used to create or rebuild a server. Rackspace provides a number of pre-built OS images by default. This data can be useful when choosing an image id to pass to the **knife rackspace server create** subcommand. You may need to use the **--rackspace-version** and **--rackspace-region** options to see nodes in different Rackspace regions.

### knife rackspace network list

Outputs a list of available networks to the currently configured Rackspace Cloud account. Networks can be added at a server during the creation process using the **--network [LABEL_OR_ID]** option. Knife does not currently support adding a network to an existing server.

### knife rackspace network create

Creates a new cloud network. Both the label and the CIDR are required parameters which are specified using the **--label LABEL** and **--cidr CIDR**

respectively. The CIDR should be in the form of 172.16.0.0/24 or 2001:DB8::/64\. Refer to <http://www.rackspace.com/knowledge_center/article/using-cidr-notation-in-cloud-networks> for more information.

### knife rackspace network delete

Deletes one or more specified networks by id. The network must be detached from all hosts before it is deleted.

### Knife & Rackspace Rackconnect

Rackspace Rackconnect allows the creation of a hybrid setup where you can have Cloud servers which are connected to bare metal hardware like Firewalls and Load balancers. You can read more about this product at <http://www.rackspace.com/cloud/hybrid/rackconnect/>

Under the hood, this changes the behavior of how the cloud servers are configured and how IP addresses are assigned to them. So when using knife-rackspace with a 'Rack connected' cloud account you need use some additional parameters. See the sections below for more information regarding the two versions of Rack Connect.

Note: If you account is leveraging private cloud networks for Rackconnnect then you are using Rackconnect v3\. You can also find your version of Rackconnect by checking with your support team

#### Knife and Rackconnect version 2

```
knife rackspace server create  \
--server-name <name of the server> \
--image <Rackspace image id> \
--flavor <Rackspace flavor id> \
-r 'role[base]' \
--rackconnect-wait
```

Note: If the server is also part of Rackspace Managed Operations service level you will need to add the

**--rackspace-servicelevel-wait** option.

```
knife rackspace server create  \
--server-name <name of the server> \
--image <Rackspace image id> \
--flavor <Rackspace flavor id> \
-r 'role[base]' \
--rackconnect-wait \
--rackspace-servicelevel-wait
```

**--rackconnect-wait** does the following:

- Rackconnect version 2 changes the networking on the cloud server and forces all trafic to route via the dedicated firewall or load balancer. It also then assigns the cloud server a new public IP address. The status of this automation provided by updates to the cloud server metadata. This option makes Knife wait for the Rackconnect automation to complete by checking the metadata.

- Once the status is updated, it triggers the bootstrap process.

**--rackspace-servicelevel-wait** does the following:

- For Cloud servers in the Managed operations service level, Rackspace installs additional agents and software which enables them to provide support. This automation. like the Rackconnect one, updates the cloud server metadata of its status. Likewise, using this option, makes knife wait till the automation is complete before triggering the bootstrap process.

#### Knife and Rackconnect version 3

In case of version 3, there is a different command line option.

```
knife rackspace server create \
--server-name <name of the server> \
--image <Rackspace image id> \
--flavor <Rackspace flavor id> \
-r 'role[base]' \
--rackconnect-v3-network-id <cloud network id>
```

**--rackconnect-v3-network-id** does the following :-

- Create the server with the corresponding cloud network. The network id the id of an existing cloud network.
- Knife will then issue additional API calls to the Rackconnect API to assign a new public IP to the cloud server. The new IP is also stored in the Cloud Server Metadata under accessv4IP.
- Knife then waits for the IP to be provisioned before triggering the bootstrap process.

Functionally, this operates the same way as version 2\. However, behind the scenes, Rackconnect v3 is significantly different in implementation. You can learn about the differences here : <http://www.rackspace.com/knowledge_center/article/comparing-rackconnect-v30-and-rackconnect-v20>

## License and Authors

```text
Author:: Adam Jacob (<adam@chef.io>)
Author:: Seth Chisamore (<schisamo@chef.io>)
Author:: Matt Ray (<matt@chef.io>)
Author:: JJ Asghar (<jj@chef.io>)
Author:: Rackspace Developers
Copyright:: Copyright (c) 2019-2016 Chef Software, Inc.
License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
