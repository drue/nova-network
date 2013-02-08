maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Installs and configures Openstack"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.18"
recipe		  "network", ""

%w{ ubuntu fedora redhat centos }.each do |os|
	  supports os
end

%w{ monitoring nova sysctl osops-utils mysql python }.each do |dep|
	  depends dep
end

