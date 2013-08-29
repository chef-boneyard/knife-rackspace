## v0.8.0
* KNIFE-68 enable ability to modify ssh port number
* KNIFE-180 include option to pass :disk_config option to fog for new node bootstrap
* KNIFE-312 updated to reflect new configuration options in Fog 1.10.1
* KNIFE-314 provisioning First Gen Cloud Server is broken
* KNIFE-315 fixed DEPRECATION warnings related to use of old rackpace_auth_url and removed rackspace_endpoint

## v0.7.0
* KNIFE_RACKSPACE-32 Ensure hint file is created to improve Ohai detection.
* KNIFE-181 correct mixed use of 'rackspace_auth_url' and 'rackspace_api_auth_url'. Only 'rackspace_auth_url' is correct.
* KNIFE-182 default to Rackspace Open Cloud (v2)
* KNIFE-267 Rackspace server create with networks
* KNIFE-271 Enable winrm authentication on knife-rackspace
* KNIFE-281 pass https_proxy and http_proxy setting onto fog; added ssl_verify_peer setting to disable certificate validation
* KNIFE-282 Add the ability to inject files on server creation
* KNIFE-289 Add Integration Tests

* KNOWN ISSUES: KNIFE-296 knife-windows overrides -x option with winrm-user

## v0.6.2
* bump release to fix permission issues inside the gem

## v0.6.0
* KNIFE_RACKSPACE-39 support for Rackspace Open Cloud (v2)
* server list puts the name in second column
* flavor list supports VCPUs for v2
* server delete for v2 will attempt the name when purging since we set the name
* docs updated to reflect all of the regions and APIs supported

## v0.5.16
* KNIFE_RACKSPACE-36 Changed to code to use IP address for bootstrapping
* KNIFE_RACKSPACE-38 Support the -P --purge option
* Refactored to use msg_pair method like other knife plugins with eye on eventual base class.
* KNIFE_RACKSPACE-29 Support private network to connect to for bootstrap
* KNIFE_RACKSPACE-40 Support for disabling host key checking
* Added the 'unknown' state to `rackspace server list`, appeared transitory

## v0.5.14
* KNIFE_RACKSPACE-25 version bump to match knife-ec2's dependencies
* KNIFE_RACKSPACE-33 chef-full is new default
* updated authors
* Fix of small typo "backspace" > "rackspace".
* KNIFE_RACKSPACE-31 chef dependency needed, add explicit gem deps
* KNIFE_RACKSPACE-7 switch to uneven_columns_across for prettier output
* updated for rackspace_api_username and the correct current image number for Ubuntu 10.04 LTS
* KNIFE-RACKSPACE-26 fog doesn't provide cores enumeration anymore
* updated copyright and removed trailing comma
* KNIFE_RACKSPACE-30 Make use of --json-attributes option for knife
  bootstrap.

## v0.5.12
* remove dependency on net-ssh and net-ssh-multi..neither is access directly in plugin
* KNIFE_RACKSPACE-18: Increase net-ssh-multi dependecy to 1.1.0
