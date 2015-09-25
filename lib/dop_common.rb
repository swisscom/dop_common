require "dop_common/version"
require "dop_common/log"
require "dop_common/validator"
require "dop_common/hash_parser"
require "dop_common/shared_options"
require "dop_common/plan"
require 'dop_common/infrastructure'
require 'dop_common/network'
require 'dop_common/affinity_group'
require 'dop_common/node'
require 'dop_common/interface'
require 'dop_common/step'
require 'dop_common/configuration'
require 'dop_common/credential'
require 'dop_common/command'
require 'dop_common/plan_cache'

module DopCommon
  PROVIDER_CLASSES = {
    :baremetal  => 'BareMetal',
    :openstack  => 'OpenStack',
    :ovirt      => 'Ovirt',
    :rhev       => 'Ovirt',
    :vsphere    => 'Vspehere',
    :vmware     => 'Vspehere',
  }
end
