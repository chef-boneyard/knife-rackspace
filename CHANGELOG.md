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
