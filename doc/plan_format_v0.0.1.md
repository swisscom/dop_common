# DOP Plan Format v 0.0.1

The DOP Plan file consists out of series of hashes and arrays which describe
system of nodes that should be created and a list of steps that need to be
performed on this nodes in order.

## Global settings

Settings that influence the whole plan

### name (optional)

The name of the plan. Make sure this name is unique among all your plan you try
to add on the same node. DOP will use this name as filename to store the plan data.
The name may only contain letters, numbers and underscores.

If no name is given, DOP will calculate the SHA2 of the plan content and use this
as a name (you will not be able to update such a plan).

### max_in_flight (optional)

`default: 3`

The amount of nodes DOP will be executing commands on in parallel.

There are also two special values:

- The value "0" will disable thread spawning for debug purposes.
- The value "-1" will spawn as many threads as there are nodes.

This option can be overwritten on step level

### max_per_role (optional)

`default: -1`

The amount of nodes per role DOPi will execute in parallel.

There are also two special values:

- The values "0" and "-1" will make DOPi ignore the roles.

This option can be overwritten on step level

### canary_host (optional)

`default: false`

If this flag is set to true DOPi will randomly choose one host and apply the step in a first round only to this host and only run the others in parallel, once this step succeeded.

This option can be overwritten on step level

## Credentials
The credentials hash can hold credentials used to login to systems, APIs or to set passwords or keys during setup.

Example:
```yaml
credentials:
 'linux_staging_login':
   type: :username_password
   username: 'root'
   password: 'foo'
 'linux_prod_login':
   type: :ssh_key
   private_key: '/home/root/.ssh/id_dsa'
 'windows_staging_login':
   type: :username_password
   username: 'administrator'
   password: 'winfoo'
 'windows_prod_login':
   type: :kerberos
   realm: 'FOOOO'
```

The various DOPi plugins can use these credentials to login to a node if the type is supported by the plugin.
It is recommended to use the set_plugin_defaults mechanic to set this credentials so it does not have to be
specified in every command separately. You can also change this defaults in your steps flow.

### Credential types

The credential types and the fields you can specify are listed here

#### username_password
A simple username password pair.

1. __*username*__ (required)
2. __*password*__ (required)

#### kerberos
Settings for a kerberos login

1. __*realm*__ (required) - The kerberos realm
2. __*service*__ (optional) - The service we try to use
3. __*keytab*__ (optional) - The keytab file to use instead of the default one

#### ssh_key
And SSH key we can use to login

1. __*username*__ (required)
2. __*private_key*__ (optional)
3. __*public_key*__ (optional)

While the public_key and private_key are optional in general, they are required depending on the usage of the
credential. If the credential is used in DOPi to login to ssh, a private key will be required and the parser will
inform you of this. If the credential is used in DOPv to set the login credentials of a vm, a public_key will be
required.

public_key and private_key can both be specified inline or be read from a file. Check the documentation about
[external secrets](#external-secrets) about how to specify this correctly.

### External secrets

Secrets like passwords or keys can be stored outside of the plan so you don't have to check them into version control.
Instead of the password you can specify a hash with only one key-value pair. The key is either :file or :exec.
The value for :file is a simple file which will be read to get the password. For :exec it is an array of where
the first entry is the executable and the rest is a bunch of options or arguments which will be joined together
and passed to the executable on the command line.

    credentials:
      'linux_staging_login':
        type: :username_password
        username: 'root'
        password:
          file: '/path/to/my_external_secret'
      'linux_prod_password':
        type: :username_password
        username: 'root'
        password:
          exec: ['/path/to/my_external_secret', '--some-option', 'arg1']

## Infrastructures
The infrastructures hash holds information about cloud providers. Each entry in
an infrastructures hash describes a certain infrastructure or cloud if you want.
It is of hash type. Following is a list of keys:
 1. __*type*__ - is the type of the infrastructure provider. It is a reuired
	property. The infrastructure provider type can be specified by following values:
    - *baremetal*,
    - *ovirt* or *rhev*,
    - *openstack*,
    - *vsphere* or *vmware*.

    Please note that *rhev* and *ovirt* are synonyms and so are *vsphere* and *vmware*.

 2. __*endpoint*__ - is an URL that is an entry point for API calls.

    __IMPORTANT__: This property is required unless the provider type is *baremetal*.

 3. __*credentials*__ - A pointer to an entry in credentials hash. Please refer
    to credentials section above for further for further information.

    __IMPORTANT__: Currently, only one credentials provider is required and
    supported for infrastructure. The credentials must be of
    __*username_password*__ type.

    __IMPORTANT__: This property is required unless the provider type is *baremetal*.

 4. __*networks*__ - provides networks definition hashes. Each network
    definition is hashed by its name that can be an arbitrary string or symbol.
	Please refer to network subsection for further details.

	__IMPORTANT__: This property is required unless the provider type is *baremetal*.

 5. __*affinity_groups*__ - provides affinity groups definition hashes. Each
affinity group definition itself is a hash. Affinity groups may be provider
specific. For instance, OVirt/RHEVm infrastructure must define __*name*__,
__*cluster*__, __*positive*__ and __*enforced*__ properties. Please note
that some providers may not have affinities implemented, hence this feature
is optional in deployment plan.

The following snippet is an example infrastructures configuration:
```yaml
infrastructures:
  management:
    type: rhev
    endpoint: https://rhev.example.com/api/
    credentials:
      username: myuser
      password: mypass
    networks:
      management:
        ip_pool:
          from: 192.168.254.11
          to: 192.168.254.245
        ip_netmask: 255.255.255.0
        ip_defgw: 192.168.254.254
    production:
        ip_pool:
          from: 192.168.1.11
          to: 192.168.1.245
        ip_netmask: 255.255.255.0
        ip_defgw: 192.168.1.254
    affinity_groups:
      clu-lab1ch-ag_1:
        positive: true
        enforce: true
        cluster: clu-lab1ch
      clu-lab1ch-ag_2:
        positive: true
        enforce: false
        cluster: clu-lab1ch
      clu-lab1ch-ag_3:
        positive: false
        enforce: true
        cluster: clu-lab1ch
  lamp:
    type: openstack
    endpoint: https://openstack.example.com/api/
    credentials:
      username: myuser
    networks:
      management-subnet:
        ip_pool:
          from: 192.168.253.11
          to: 192.168.253.245
        ip_netmask: 255.255.255.0
        ip_defgw: 192.168.253.254
      production-subnet:
        ip_pool:
          from: 192.168.2.11
          to: 192.168.2.245
        ip_netmask: 255.255.255.0
        ip_defgw: 192.168.2.254
  db:
    type: vsphere
    endpoint: https://vsphere.example.com/api/
    credentials:
      username: myuser
      password: mypass
    networks:
      management:
        ip_pool:
          from: 192.168.252.11
          to: 192.168.252.245
        ip_netmask: 255.255.255.0
        ip_defgw: 192.168.252.254
      production:
        ip_pool:
          from: 192.168.3.11
          to: 192.168.3.245
        ip_netmask: 255.255.255.0
        ip_defgw: 192.168.3.254
```

### Network
The network hash describes a particular network within a given infrastructure
provider (cloud). Following are the properties of a network hash:
 1. __*ip_pool*__ - a hash of IP addresses which can be assigned to guest VMs.
    The hash must contain __*ip_from*__ and __*ip_to*__ keywords that specify
    the lower and upper bounds of IP addresses that can be assigned statically.
 2. __*ip_netmask*__ - a network mask in octet format.
 3. __*ip_defgw*__ - an IP address of the default gateway of the network.

__NOTE__: One might also specify an empty hash `{}` as netwrok properties in
case of pure DHCP or NONE-based networks.

__IMPORTANT__: Please note that network names must refer to sub-network names
or their identifiers in case of [OpenStack](http://www.openstack.org/) based
infrastructures.

## Nodes

The nodes hash holds the basic information about all nodes you want to create
and use. Each entry in the nodes hash is itself a hash. A single entry of this
is called a node hash (singular). Each node hash starts with the node name as a
key:

```yaml
nodes:
    mysql01.example.com:
      ...
      ...
      ...
```

__IMPORTANT__: The node name must be unique for each deployment. Please keep
this in mind when combining several deployments into a single deployment file.

### Node Properties
Each node configuration is described by a so-called *"node hash"*. The list
bellow provides an overview of various node properties. Please note that
a property name is actually a keyword of a node hash.

 1. __*fqdn*__ - an optional fully qualified domain name that is used to
    generate the hostname of the guest. If not defined, the hostname is implicitly
    derived from the node name itself (for instance, in case of
    `mgt01.example.com`, the hostname definition would match the node name, i.e.
    `mgt01.example.com`).

 2. __*infrastructure*__ - a name of the  infrastructure this node is a part of.
    This is a required property and its value must point to a valid entry of
    infrastructures hash.

 3. __*infrastructure_properties*__ - a hash that specifies various properties
    of a given node should be deployed with in an infrastructure.

    1. __*affinity_groups*__ - an optional OVirt/RHEVm-specific property that
       designates what affinity groups should be a node associated with.

    2.  __*keep_ha*__ - an optional OVirt/RHEVm-specific boolean property that
        indicates whether the VM should be highly available or not. By default,
        instances are set as highly available. If the provider also supports a
        migration priorities they are set to low by default.

    3. __*datacenter*__ and __*cluster*__ - Specify which datacenter and cluster
       should be the node deployed into.

       __IMPORTANT__: These properties are required for provider OVirt/RHEVm and
       VSphere providers. Other providers silently disregard it.

    4. __*default_pool*__ - property specifies the default data storage which is
       used when deploying a guest from the template. It is also used for persistent
       disks that do not specify an explicit __*pool*__. This attribute is optional.

    5. __*dest_folder*__ property defines a destination folder into which the
       guest shall be deployed. This folder must exist before the deployment
       of the guest. This is propery is optional and VSphere-specific.

    6. __*tenant*__ property specifies the name of the tenant for OpenStack
       infrastructures. It is required for OpenStack infrastructures.

	7. __*use_config_drive*__ an optional OpenStack-specific boolean property
	   that specifies whether a config drive should be used for VM
	   provisioning. If set to `false` or indefined, metadata service is
	   used. If set to `true` config drive is used.
    
	8. __*domain_id*__ an optional property specifies the name of the domain ID
	   for OpenStack infrastructures. It defaults to `default`.
	
	9. __*endpoint_type*__ an optional property specifies the endpoint type
	   for OpenStack infrastructures. Accepted values are `publicURL`,
	   `internalURL` and `adminURL`. It defaults to `publicURL`.

    __IMPORTANT__: Infrastructure properties may differ across different
    provider types.

    __IMPORTANT__: In general, some of infrastructure properties have to be
    defined for each provider other than *baremetal*.

 4. __*image*__ - an image to deploy the node from (a.k.a template). An image
    must be registered within the provider.

	__IMPORTANT__: This property is required unless the provider type is
	*baremetal*.

 5. __*full_clone*__ - an optional boolean property that instructs OVirt/RHEVm
	providers:
    1. To provision a node from a template as a full independent clone if set to
       `true` or unset.

    2. To provision a node from a template as thin (dependent) clone if set to
       `false`.

    The default is to provision a fully independent clone.

    __IMPORTANT__: Do not use this property for other cloud provider types than
    OVirt/RHEVm.

 6. __*interfaces*__ - network interface hash cards specification. Each NIC is
    hashed by its name (for instance, *eth0*, *eth1*, etc).

    __IMPORTANT__: For Linux guests, the NIC name defined in a plan should
	correspond to its logical name in the guest OS.

	__NOTE__: NICs are ordered and configured within the the guest OS in the
	order they were defined in the plan.

	__IMPORTANT__: This property is required unless the provider type is
	*baremetal*.

    Following is a list of properties that descirbe a network interface card:
    1. __*network*__ - name of the network the NIC belongs to. The network
       must exist in infrastructures' networks hash.

       __IMPORTANT:__ In case of OpenStack providers, the network name must
       point to valid subnet rather than a network name.

    2. __*ip*__ - a property that defines an IP address. Following values are
       permitted:
       - a properly formatted string witn an IP in case of static,
       - a *dhcp* literal in case the IP should by assigned by DHCP,
       - *none* literal in case no IP adress should be set for a given interface.

    3. __*set_gateway*__ - an optional boolean property that defines, whether a
       gateway should be defined for a given interface during guest customization.
       It is `true` by default.

    4. __*virtual_switch*__ - an optional (currently VSphere-specific) property
       that specifies which distributed virtual switch should be used.

    5. __*floating_network*__ - an optional OpenStack specific property that
       specifies the network from which is the __floating__ IP provisioned and
       associated with the interface.

 7. __*disks*__ - an optional property to define additional disks that should
    persist accross deployments. It is of hash type. The key represents a disk
	name. A persistant disk itself is described by a so-called *"disk hash"*
	with following keywords:
    1. __*pool*__ - the name of the storage pool that should be used as a backing
       store for a disk. It is required for OVirt/RHEVm and VSphere providers,
       unless the __*default_pool*__ is specified in
       __*infrastructure_properties*__.
    2. __*size*__ - the size of the disk in megabytes (when the value has a
       suffix *M*) or gigabytes (when the value has a suffix *G*).
    3. __*thin*__ - an optional boolean flag that indicates whether the disk will be
       thin provisioned. Its default  value is *true*, meaning the disks are
       thin-provisioned by default. Please use *false* as the value if you need to
       thick provision a disk.

       __IMPORTANT:__ Currently, the selection of provisioning type is honored
       only by OVirt/RHEVm provider. A thick-provisioned disk in OVirt/RHEVm
       provider is of __raw__ rather than __cow__ type. As a consequence,
       it is not possible to create a snapshot of such a disk.*

 8. __*credentials*__ - an optional property to define credentials for
    administrator user (root, Administrator). This information is passed to
	the customization tool (cloud-init, VSphere customization, etc.). Following
	data can be specified:
    * __*root_password*__ - super user password that is set for cloud init phase,
    * __*root_ssh_keys*__ - an array of OpenSSH public keys that are recorded
      into `/root/.ssh/authorized_keys` by cloud init.
    * __*administrator_password*__ - an optional property that specifies the
      password of the administrator user for VSphere-based windows-guests
      customization. it defaults to an empty password which in turn leads to an
      automatic logon upon windows guest startup.

 9. __*flavor*__ - an optional property that specifies how to set the amount of
     CPU cores, memory and the size of the *root* disk. Please consult
     [OpenStack
     flavors](http://docs.openstack.org/openstack-ops/content/flavors.html) for
     their definition. In case the infrastructure does not support flavors feature,
     it is emulated.

     __IMPORTANT:__ The __flavor__ property is mutually exclusive with any of
	 __cores__, __memory__ or __storage__ properties. Having said that, an
	 exception will logged if __flavor__ is specified along with one or more
	 of __cores__, __memory__ and/or __storage__ properties.

 10. __*cores*__ - an optional positive integer that sets the number of cores
    for a given node.
	
	It is `2` by default.

 11. __*memory*__ - an optional value that is used to set the amount of
     provisioned memory for a given node.

	 The format of an input value is a positive number followed by one of:
     * `K` for kibibytes,
	 * `M` for mebibytes,
	 * `G` for gibibytes,
	 * `KB` for kilobytes,
	 * `MB` for megabytes,
	 * `GB` for gigabytes.

	 The default is `4G`.

 12. __*storage*__ - an that specifies the size of the root volume.

     Please note that some infrastructure providers disregard this value,
	 especially when the node is provisioned from a template.

	 Please have a look to __*memory*__ for formatting of input value.
     
	 The default value is `10G`.

 13. __*timezone*__ - a property that specifies the timezone of the guest
     operating system. Please make sure that:
      * [following values are
        used](https://www.vmware.com/support/developer/windowstoolkit/wintk40u1/html/New-OSCustomizationSpec.html)
        for VSphere-based windows guests customization,
      * for Linux guests, values specified in a __`TZ`__ column of the [list of
        tz databaze time zones](http://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
        are used.

     __IMPORTANT:__ This property is required when customizing guest on *VSPhere* provider.

 14. __*product_id*__ - an optional, VSphere-specific windows-only guest customization
     property that specifies a serial number. Its default value is
     undefined which leaves the guest OS in an evaluation/trial mode.

 15. __*organization_name*__ - a required, VSphere-specific windows-only guest
     customization property that specifies the organization name of the
     administrator user.

 16. __*dns*__ - an optional property that specifies name servers and search
	 domains for further node customization. If specified, it has to be a hash
	 with any of the following items:
	 1. __*name_servers*__ - a list of valid IP addresses.
	 2. __*search_domains*__ - a list of valid domains.

The example bellow shows a specification for a database backend and a web node:
```yaml
nodes:
  mgt01.example.com:
    infrastructure: management
    infrastructure_properties:
      affinity_groups:
        - clu-lab1ch-ag_1
        - clu-lab1ch-ag_3
      keep_ha: false
      datacenter: lab1ch
      cluster: clu-lab1ch
      default_pool: ssd_pool1
      full_clone: false
    image: rhel6cloudinit
    interfaces:
      eth0:
        network: management
          ip: dhcp
    credentials:
      root_password: a_password
      root_ssh_keys:
        - OpenSSH key 1
        - OpenSSH key 2

  mssql01_mgt01:
    fqdn: mssql01.example.com
    infrastructure: management
    infrastructure_properties:
      datacenter: lab1ch
      cluster: clu-lab1ch
      keep_ha: true
    image: win12r1_64
    cores: 6
    memory: 64G
    storage: 128G
    interfaces:
      eth0:
        network: management
        ip: 192.168.254.13
    disks:
      db1:
        pool: storage_pool3
        size: 256G
		thin: false
    credentials:
      root_password: a_password

  mysql01.example.com:
    infrastructure: lamp
    infrastructure_properties:
      tenant: lamp01
    image: rhel6cloudinit
    flavor: medium
    interfaces:
      eth0:
        network: management-subnet
        ip: 192.168.253.25
      eth1:
        network: production-subnet
        ip: 192.168.2.102
		floating_network: ext-net0
    disks:
      rdo:
        pool: storage_pool1
        size: 4000M
		thin: false
      db1:
        size: 20G

  mssql01.example.com:
    infrastructure: db
    infrastructure_properties:
      dest_folder: sql
      datacenter: dc01
      cluster: cl01
	  default_pool: sql_pool
    image: w12r2
    flavor: medium
    interfaces:
      eth0:
        network: management
        ip: 192.168.252.33
		set_gateway: false
      eth1:
        network: db
        ip: 192.168.3.109
    disks:
      rdo:
        pool: storage_pool3
        size: 4000M
		thin: false
      db1:
        size: 20G
    credentials:
      administrator_password: ASecurePassw0rd
	timezone: 100
    organization_name: Acme

  web01.example.com:
    infrastructure: lamp
    infrastructure_properties:
      tenant: lamp01
    datacenter: lab1ch
    cluster: clu-lab1ch
    image: rhel6
    flavor: small
    interfaces:
      eth0:
        network: management-subnet
        ip: 192.168.253.26
      eth1:
        network: production-subnet
        ip: dhcp
		floating_network: ext-net0
```


## Configuration

The configurations hash contains hashes with settings for nodes and roles

### Nodes

the nodes configuration hash assigns variables to an individual node or to a selected set of nodes. Here are some examples:

```yaml
configuration:
  nodes:
    mysql01.example.com:
      role: mysql
      my_var:  my_value
    web04.example.com:
      role: httpd_special
```

The only relevant setting here for DOP is the role variable. The name of the role variable can be configured but defaults to 'role'. If hiera is configured and activated, then dop_common will take the role specified in hiera if found. The hierarchy for the role resolution is as follows:

1. Hiera
2. fqdn match in nodes configuration in Plan file
4. Default

A node always needs a role. If the parser finds no value for one of the specified nodes in the plan file and if no default is set, the dop_common will throw an error.

### Roles

You can set variables for a specific role in this hash.

```yaml
configuration:
  roles:
    mysql:
      mysql::default_database:
        name: mydatabase
        user: myuser
        password: mypass
```

This is only used from puppet over the hiera plugin and not from DOP itself at the moment.

## Steps and step sets

The steps array is a list of commands that have to be executed in the correct order. Each element in the array contains a hash of settings which describe the step, the nodes involved and the command to execute.

Example:
```yaml
steps:
  - name: run_puppet_on_mysql
    nodes:
      - mysql01.example.com
    command: ssh_run_puppet

  - name: run_puppet_on_webserver
    roles:
      - httpd_basic
      - https_special
    command: ssh_run_puppet

  - name: reboot_all_nodes
    nodes: all
    command: ssh_reboot

  - name: run_puppet_in_noop_on_proxies
    roles:
      - haproxy
    command:
      plugin: ssh_puppet_run
      arguments:
        '--noop':
```

You can define multiple sets of steps which can be executed independently of each other.

Example:
```yaml
steps:
  'default':
    - name: run_puppet_on_mysql
      nodes:
        - mysql01.example.com
      command: ssh_run_puppet

    - name: run_puppet_on_webserver
      roles:
        - httpd_basic
        - https_special
      command: ssh_run_puppet

  'maintenance':
    - name: reboot_all_nodes
      nodes: all
      command: ssh_reboot

    - name: run_puppet_in_noop_on_proxies
      roles:
        - haproxy
      command:
        plugin: ssh_puppet_run
        arguments:
          '--noop':
```

The run command will always execute the 'default' step set if nothing else is specified. If only one set is
specified in the array form without a name this set will have the name 'default'.

### name

The name is just an identifier for the step. You should chose a name that best describes what you are doing in this step.

### nodes

This can either be one or a list of nodes and/or Regex patterns or the keyword "all" which will include all nodes for the step.

If an entry starts and ends with a '/' DOPi will interpret the string as a regular expression.

### set_plugin_defaults

(This will be in DOPi >= 0.4)

With "set_plugin_defaults" it is possible to specify some default values for plugin configuration which will persist over subsequent runs.

The settings are node specific, so they will only be set for the nodes in your step. You can select the plugins for which this applies with
a list or with regular expressions.

Direct settings in the plugins will always overwrite the defaults.

IMPORTANT: The keys you want to set have to be ruby symbols. This is a current limitation of the way the parser is implemented and may change in the future

Example:
```yaml

steps:
  - name: "Set default passwords for Plugins"
    nodes: all
    set_plugin_defaults:
      - plugins: '/^ssh/'
        :credentials: 'linux_staging_password'
      - plugins: '/^winrm/'
        :credentials: 'windows_staging_password'
      - plugins:
        - 'ssh/custom'
        :quiet: false

```

### delete_plugin_defaults

(This will be in DOPi >= 0.4)

There are several possibilities how you can remove plugin settings with "delete_plugin_defaults"

IMPORTANT: The keys you want to set have to be ruby symbols. This is a current limitation of the way the parser is implemented and may change in the future

Example:
```yaml
  - name: "Remove some specific defaults for all nodes"
    nodes: all
    delete_plugin_defaults:
      - plugins: '/^ssh/'
        delete_keys:
          - :credentials
          - :timeout

  - name: "Remove all the defaults for the ssh plugins for all nodes in role 'foo'"
    roles:
      - foo
    delete_plugin_defaults:
      - plugins: '/^ssh/'
        delete_keys: all

  - name: "Remove all the defaults for all plugins for all nodes"
    nodes: all
    delete_plugin_defaults: all

```

### nodes_by_config

Include nodes to a step by specific configuration values which are resolved over hiera.

Example:
```yaml

configuration:
  nodes:
    'mysql01.example.com':
      'my_alias': 'database_01'

steps:
  - name: 'include by config'
    nodes_by_config:
      'my_alias': 'database_01'
    command: ssh_run_puppet

```

If the value of the config variable is an array it will check each value in that array. You can also use pattern here like with node

Example:
```yaml

configuration:
  nodes:
    'mysql01.example.com':
      'my_alias':
        - 'database_01'
        - 'some_other_alias'

steps:
  - name: 'include by config'
    nodes_by_config:
      my_alias:
        - '/^linux/'
        - 'database_01'
    command: ssh_run_puppet

```

### roles

This will include all the nodes with a certain role to a step.

roles and nodes can be mixed, dop_common will simply merge the list of nodes. However there has to be at least one node in every step.

If an entry starts and ends with a '/' DOPi will interpret the string as a regular expression.

roles is basically just a special case for nodes_by_config with the roles variable. But it will do some additional checks and you can also set
a default value for the role on DOPi.

### exclude_nodes

A list of nodes to exclude from the list that gets assembled from nodes and roles. This can also contain Regex patterns like nodes and roles.

### exclude_nodes_by_config

Exclude nodes based on config values and matching patterns.

### exclude_roles

Works exactly like exclude_nodes but excludes roles.

### commands

The commands can either be directly a plugin name if a simgle plugin and no parameters, a single command hash which will be passed to the plugin or an array of command hashes if multiple commands have to be executed in a single step. The only fixed variable here is the **plugin** variable. The rest of the variables in the command hash depends on the plugin in use and how it will parse the hash.

For more documentation about the plugins and the variables available for configuring them, check the DOPi documentation.

# Examples

For a complete example plan file see:
[DOP Plan Format v 0.0.1 Example](examples/example_deploment_plan_v0.0.1.yaml)
