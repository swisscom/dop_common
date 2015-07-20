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

### ssh_root_pass (optional)

The default password the ssh plugin will use to login on remote hosts if password login is enabled and sshpass is installed. This value can be overwritten via Hiera. DOPi will always try to lookup the variable over Hiera first and use this default if it finds nothing.

### canary_host (optional)

`default: false`

If this flag is set to true DOPi will randomly choose one host and apply the step in a first round only to this host and only run the others in parallel, once this step succeeded.

This option can be overwritten on step level

## Infrastructures
The infrastructures hash holds information about cloud providers. Each entry in
an infrastructures hash describes a certain infrastructures or cloud if you want.
It is of hash type. Following is a list of keys:
 1. __*type*__ - is the type of the infrastructure provider. Its value must be
one of the following strings: *baremetal*, *ovirt*, *rhev*, *openstack*,
*vsphere*, *vmware*.
Please note that *rhev* and *ovirt* are synonyms and so are *vsphere* and
*vmware*. This is a required key.
 2. __*endpoint*__ - is a URL that is an entry point for API calls. This is
 required.
 3. __*credentials*__ - credential hash. The content of this hash depends on a
infrastructure provider type. For instance, RHEV infrastructure must contain
__*username*__ and __*password*__. VSphere-based infrastructure also require a
key, specified by __*provider_pubkey_hash*__. OpenStack-based infrastructure must
have __*username*__ and __*provider_pubkey_hash*__ sepcified. Credential hash
specification is required, although its content - as one might have noticed -
may differ across different providers.
 4. __*networks*__ - provides networks definition hashes. Each network definition
is hashed by its name that can be an arbitrary string or symbol. Please refer to
network subsection for further details.
 5. __*affinity_groups*__ - provides affinity groups definition hashes. Each
affinity group definition itself is a hash. Affinity groups may be provider
specific. For instance, RHEV infrastructure must define __*name*__,
__*cluster*__, __*positive*__ and __*enforced*__ properties. Plese note tha some
providers may not have affinities implemented, hence this feature is optional in
deployment plan.

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
	  provider_pubkey_hash: e32af...
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
Network hash describes a particular network within a given infrastructure
provider (cloud). Following are the properties of network hash:
 1. __*ip_pool*__ - a hash of assignable IP addresses. The hash must contain
__*ip_from*__ and __*ip_to*__ keywords that specify the lower and upper bounds
of IP addresses that can be assigned statically.
 2. __*ip_netmask*__ - a network mask in octet format.
 3. __*ip_defgw*__ - an IP address of the default gateway of the network. This
is optional.

__IMPORTANT__: Please note that network names must refer to sub network names or
their identifiers in case [OpenStack](http://www.openstack.org/) cloud software
is used.

## Nodes

The nodes hash holds the basic information about all the nodes you want to
create and use. Each entry in the nodes hash is itself a hash. A single entry of
this is called a node hash (singular). Each node hash starts with the node name
as a key:

```yaml
nodes:
    mysql01.example.com:
    ...
```

__IMPORTANT__: The node name must be unique for each deployment. Please keep
this in mind when combining several deployments into a single deployment file.

### Node Properties
Each node configuration is described by a so-called node hash. The list bellow
provides an overview on various node properties. Please note that property
name is also a keyword of node hash.
 1. __*fqdn*__ - an optional fully qualified domainname that is used to generate
 the hostname of the guest. If not defined, the hostname is implicitly derived
 from the node name itself (for instance, in case of `mgt01.example.com`, the
 hostname definition would match the node name, i.e. `mgt01.example.com`).
 2. __*infrastructure*__ - an infrastructure name this node is a part of. This
is a required property and its value must point to a valid entry in an
infrastructures hash.
 3. __*infrastructure_properties*__ - infrastructure properties. It is of hash
type. This property is optional. Infrastructure properties may differ accross
different provider types. Currently, this hash may contain __*affinity_groups*__,
__*keep_ha*__, __*datacenter*__ and __*cluster*__ keywords.
   1.  __*affinity_groups*__ property designates what affinity group should be
   assigned a specific node assigned to and is likely RHEV/oVIRT specific.
   2.  __*keep_ha*__ property is of boolean type and indicates whether the VM
   should be highly available or not. By default, instances are set as highly
   available. If the provider also supports a migration priorities they are set
   to low by default.
   3. __*datacenter*__ and __*cluster*__ allow to specify under which cluster in
   which datacenter should the node be deployed. These properties are specific
   to RHEV/oVIRT and VSphere infrastructure providers.
   4. __*default_pool*__ property specifies the default data storage which is
   used when deploying a guest from the template. It is also used for persistent
   disks that do not specify an explicit __*pool*__. This attribute is optional.
   5. __*dest_folder*__ property defines a destination folder into which the
   given guest shall be deployed. This folder must exist before the deployment
   of the guest. This is propery is optional and VSphere-specific.
   6. __*tenant*__ property specifies the name of the tenant for OpenStack
   infrastructures.
 4. __*image*__ - image to deploy the node from (a.k.a template). This property
is of string type and it is required. An image must be registered within
provider.
 5. __*full_clone*__ - an optional boolean property that instructs OVirt/RHEV:
   1. To provision a node from a template as a full independent clone if set to
   `true`
   2. To provision a node from a template as thin (dependent) clone if set to
   false or unset.
 The default is to provision a fully independent clone.
 6. __*interfaces*__ - network interface cards specification. This property is
required and it is of hash type. Each NIC is hashed by its name (for instance,
*eth0*, *eth1*, etc). NIC name has to correspond with a name the OS recognizes
it. Please note that NICs are indexed in the OS in the order they were defined
in the plan. Following is a list of properties of a given network interface
card:
   1. __*network*__ - name of the network the NIC belongs to. The network must be
   a valid definition in an infrastructures' networks hash. This definition is
   required.

   __IMPORTANT:__ For OpenStack provider, the network name must point to a valid
   subnet rather than a network name.

   2. __*ip*__ - an optional property that defines an IP address in case of
   static IP assignment or a *dhcp* literal if the IP should be assigned by DHCP.
   3. __*set_gateway*__ - an optional boolean property that defines, whether a
   gateway should be defined for a given interface during guest customization.
   It is `true` by default.
   4. __*virtual_switch*__ - an optional (currently VSphere-specific) property
   that specifies which distributed virtual switch should be used.

   __IMPORTANT:__ The current implementation of cloud-init in *fog* and its
   underlying library *rbovirt* does not support DHCP nor multiple NIC
   configurations, hence the cloud-init is applied by DOPv onto the first
   interface which has a static IP in its definition. Please note that there is
   another bug in *rbovirt* that prevents statically defined interface from
   being configured if one of the parameters netmask or gateway is undefined.

   5. __*floating_network*__ - an optional OpenStack specific property. It is
   the name of the network that within the __floating__ IP is created and
   associated with the given interface.

 7. __*disks*__ - an optional property to list additional disks that should
 persist accross deployments. It is of array type. A persistant disk itself
 is described by a so-called disk hash with following keywords:
   1. __*name*__ - disk name. It is required.
   2. __*pool*__ - the name of the storage pool that should be used as a backing
   store for a disk. This property is required unless  the __*default_pool*__ is
   specified in __*infrastructure_properties*__.
   3. __*size*__ - the name size of the disk in megabytes (when the value has a
  suffix *M*) or gigabytes (when the value has a suffix *G*).
   4. __*thin*__ - an optional boolean flag that indicates whether disk will be
   created as thin provisioned. Its default  value is *true*, meaning the
   disks are thin-provisioned by default. Please use *false* as the value if
   you need to thick provision a disk.
 
 __IMPORTANT:__ Currently, the selection of provisioning type is honored only
 by the RHEVm/OVirt provider. Please also note that a thick-provisioned disk
 is of *raw* rather than *cow* type when thick provisioning is used. As a
 consequence, it is not possible to create a snapshot of such a disk
 OVirt/RHEVm.

 8. __*credentials*__ - an optional property to define credentials for root
 user. This information is passed to cloud init. Following data can be
 specified:
   * __*root_password*__ - super user password that is set for cloud init
   phase,
   * __*root_ssh_keys*__ - an array of OpenSSH public keys that are recorded
   into `/root/.ssh/authorized_keys` by cloud init.
   * __*administrator_fullname*__ - an optional property that specifies the full
   name of the administrator user for VSphere-based windows-guests
   customization. It defaults to `Administrator`, 
   * __*administrator_password*__ - an optional property that specifies the
   password of the administrator user for VSphere-based windows-guests
   customization. it defaults to an empty password which in turn leads to an
   automatic logon upon windows guest startup, 
 9. __*cores*__ - an optional integer that sets the number of cores for a given
 node. It is `2` by default.
 10. __*memory*__ - an optional string of numbers followed by one of `M`/`m`
 (mega) or `G`/`g` (giga) character. It is used to set the amount of
 provisioned memory. The default is `4G`.
 11. __*storage*__ - an optional string of numbers followed by one of `M`/`m`
 (mega) or `G`/`g` (giga) character. It is used to set the amount of
 provisioned *root* disk space. Please note that some infrastructure providers
 disregard this value, especially when the node is provisioned from a template.
 The default value is `10G`.
 12. __*flavor*__ - an optional property that specifies how to set the amount of
 CPU cores, memory and to specify the size of the *root* disk. Please consult
 [OpenStack
 flavors](http://docs.openstack.org/openstack-ops/content/flavors.html) for
 their definition. In case the infrastructure does not support flavors feature,
 it is emulated.
 
 __IMPORTANT:__ Use of __*flavor*__ always overrides the values explicitly set
 by either of __*cores*__, __*memory*__ or __*storage*__ properties.
 
 13. __*timezone*__ - an optional property that specifies the timezone of the
 guest operating system. Please make sure that:
   * for VSphere-based windows guests customization [following values are
   used](https://www.vmware.com/support/developer/windowstoolkit/wintk40u1/html/New-OSCustomizationSpec.html),
   * for Linux guests, use values specified in a __`TZ`__ column of the [list of
   tz databaze time zones](http://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

 __IMPORTANT:__ As this property is optional, its default value is infrastructure
 provider specific. Some providers (RHEV/oVIRT) do not require this property to
 be set during customization, while others (VSphere) do. The rule of the thumb
 is tha in case the provider requires the time zone to be specified, it defaults
 to GMT.

 14. __*product_id*__ - an optional, VSphere-based windows-only guest customization
 property that specifies a serial number. Its default value is
 undefined which leaves the guest OS in an evaluation/trial mode.

 15. __*organization_name*__ - a required, VSphere-based windows-only guest 
 customization property that specifies the organization name of the
 administrator user.

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
      - name: db1
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
      - name: rdo
        pool: storage_pool1
        size: 4000M
      - name: db1
        size: 20G

  mssql01.example.com:
    infrastructure: db
    infrastructure_properties:
      dest_folder: sql
	  datacenter: dc01
      cluster: cl01
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
      - name: rdo
        pool: storage_pool3
        size: 4000M
      - name: db1
        pool: storage_pool3
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

## Steps

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

### name

The name is just an identifier for the step. You should chose a name that best describes what you are doing in this step.

### nodes

This can either be one or a list of nodes and/or Regex patterns or the keyword "all" which will include all nodes for the step.

If an entry starts and ends with a '/' DOPi will interpret the string as a regular expression.

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

### command

The command can either be directly a plugin name if no parameters are needed or a command hash which will be passed to the plugin. The only fixed variable here is the **plugin** variable. The rest of the variables in the command hash depends on the plugin in use and how it will parse the hash.

For more documentation about the plugins and the variables available for configuring them, check the DOPi documentation.


# Examples

For a complete example plan file see:
[DOP Plan Format v 0.0.1 Example](examples/example_deploment_plan_v0.0.1.yaml)
