# knife-rackspace Change Log

<!-- latest_release -->
<!-- latest_release -->

<!-- release_rollup -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v2.0.2](https://github.com/chef/knife-rackspace/tree/v2.0.2) (2019-12-30)

#### Merged Pull Requests
- MSYS-1071 Updated README.md as per Chef OSS [#147](https://github.com/chef/knife-rackspace/pull/147) ([NAshwini](https://github.com/NAshwini))
- Substitute require for require_relative [#148](https://github.com/chef/knife-rackspace/pull/148) ([tas50](https://github.com/tas50))
<!-- latest_stable_release -->

## [v2.0.0](https://github.com/chef/knife-rackspace/tree/v2.0.0) (2018-11-28)

#### Merged Pull Requests
- Require Ruby 2.3+/Chef 13+ and remove deprecated bootstrap options [#146](https://github.com/chef/knife-rackspace/pull/146) ([tas50](https://github.com/tas50))

## [v1.0.5](https://github.com/chef/knife-rackspace/tree/v1.0.5) (2018-11-20)

#### Merged Pull Requests
- Only ship the necessary libraries in the gem [#144](https://github.com/chef/knife-rackspace/pull/144) ([tas50](https://github.com/tas50))
- Expand ruby testing in Travis [#145](https://github.com/chef/knife-rackspace/pull/145) ([tas50](https://github.com/tas50))



## v1.0.3
* Fix to encrypted_data_bag_secret and encrypted_data_bag_secret_file options (#138)
* Fix em-winrm dependencies and close TCP sockets (#134)

## v1.0.2
* Fix issue in error message when no flavor is supplied (#132)

## v1.0.1
* Fix Server List exception (#131)
* Fix bug preferring knife over CLI configurations items (#128)

## v1.0.0
* Use fog/rackspace instead of fog gem
* Require Ruby 2.2.2 / Chef 12 and general cleanup
* Spec updates to avoid deprecation warnings
* Chefstyle fixes
* Modified server list - #118

## v0.11.1
* Remove unused, and unsupported/ancient knife-dsl requirement
* Take it all the way to 11 (Chef 11.x) and greater

## v0.11.0
* Add -B (boot volume ID) to `knife rackspace server create` - #91

## v0.10.1
* Support new chef-vault boostrap flags (--bootstrap-vault-file, -bootstrap-vault-json, and --bootstrap-vault-item)

## v0.10.0
* KNIFE-498 knife rackspace uses direct TCP connection on port 22 to verify SSHD
* Update Windows bootstrapping instructions in the README
* Fix warning for deprecated :keypair for :key_name

## v0.9.3
* KNIFE-497 Create server command does not honor timeout parameter

## v0.9.2
* KNIFE-480 Add support for user-data
* --secret-file support for bootstrap

## v0.9.1
* KNIFE-460 Remove extraneous flavor reloads
* KNIFE-459 Add support for config-drive
* KNIFE-440 fix two minor typos in the ui.error message
* use {public_ip_address}.xip.io instead of {public_ip_address}.rs-cloud.xip.io

## v0.9.0
* KNIFE-398 support secret/secret_file in knife.rb
* KNIFE-420 Add --ssh-keypair for using ssh keys already registered with nova.
* KNIFE-437 remove default region and make region required
* replace static.cloud-ips with xip (cloud-ips was deprecated https://community.rackspace.com/general/f/34/t/623)
* updated Fog dependency to 1.16

## v0.8.4
* KNIFE-408 TypeError: wrong argument type Symbol (expected Module)

## v0.8.2
* KNIFE-335 Wait for RackConnect and/or Service Level automation before bootstrapping
* KNIFE-366 Allow arbitrary bootstrap networks
* KNIFE-399 update knife rackspace to support string based flavor ids
* Fixing issue with bootstrapping Windows server
* Fog 1.16 updates

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