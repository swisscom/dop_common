# DOP Plan Format v 0.0.1

The DOP Plan file consists out of series of hashes and arrays which describe system of nodes that should be created and a list of steps that need to be performed on this nodes in order.

## Infrastructure
The infrastructure hash holds information about cloud providers. Each entry in
an infrastracture hash describes a certain infrastructure or cloud if you want.
It is of hash type. Following is a list of keys:
 1. __*type*__ - is the type of the infrastructure provider. Its value must be
one of the following strings: *ovirt*, *rhev*, *openstack*, *vsphere*, *vmware*.
Please note that *rhev* and *ovirt* are synonyms and so are *vsphere* and
*vmware*. This is a required key.
 2. __*endpoint*__ - is a URL that is an entry point for API calls. This is
 required.
 3. __*credentials*__ - credential hash. The content of this hash depends on a
infrastructure provider type. For instance, RHEV infrastructures must contain
__*username*__ and __*password*__ keys. Credential hash specification is
required, although its content may differ across different providers.
 4. __*networks*__ - provides networks definition hashes. Each network definition
is hashed by its name that can be an arbitrary string or symbol. Please refer to
network subsection for further details.
 5. __*affinity_groups*__ - provides affinity groups definition hashes. Each
affinity group definition itself is a hash. Affinity groups may be provider
specific. For instance, RHEV infrastructure must define __*name*__,
__*cluster*__, __*positive*__ and __*enforced*__ properties. Plese note tha some
providers may not have affinities implemented, hence this feature is optional in
deployment plan.

The following snippet is an example infrastructure configuration:
```yaml
infrastructure:
  management:
    type: rhev
    endpoint: https://rhev.example.com/api/
    credentials:
      username: myuser
      password: mypass
    networks:
      rhevm:
        ip_pool:
          from: 192.168.254.11
          to: 192.168.254.245
        ip_netmask: 255.255.255.0
        ip_defgw: 192.168.254.254
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
      password: mypass
    networks:
      management:
        ip_pool:
          from: 192.168.253.11
          to: 192.168.253.245
        ip_netmask: 255.255.255.0
        ip_defgw: 192.168.253.254
      production:
        ip_pool:
          from: 192.168.1.11
          to: 192.168.1.245
        ip_netmask: 255.255.255.0
        ip_defgw: 192.168.1.254
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

### Node Properties
Each node configuration is described by a so-called node hash. The list bellow
provides an overview on various node properties. Please note that property
name is also a keyword of node hash.
 1. __*infrastructure*__ - an insfrastructure name this node is a part of. This
is a required property and its value must point to a valid entry in an
infrastructure hash.
 2. __*infrastructure_properties*__ - infrastructure properties. It is of hash
type. This property is optional. Infrastructure properties may differ accross
different provider types. Currently, this hash may contain __*affinity_groups*__,
__*keep_ha*__, __*datacenter*__ and __*cluster*__ keywords.
   1.  __*affinity_groups*__ property designates what affinity group should be
   assigned a specific node assigned to and is likely RHEV/oVIRT specific.
   2.  __*keep_ha*__ property is of boolean type and indicates whether the VM
   should be highly available or not. By default, instances are set as highly
   available. If the provider also supports a migration priorities they are set
   to high by default.
   3. __*datacenter*__ and __*cluster*__ allow to specify under which cluster in
   which datacenter should the node be deployed. These properties are specific
   to RHEV/oVIRT and VSphere infrastructure providers.
 3. __*image*__ - image to deploy the node from (a.k.a template). This property
is of string type and it is required. An image must be registered within
provider.
 4. __*interfaces*__ - network interface cards specification. This property is
required and it is of hash type. Each NIC is hashed by its name (for instance,
*eth0*, *eth1*, etc). NIC name has to correspond with a name the OS recognizes
it. Please note that NICs are indexed in the OS in the order they were defined
in the plan. Following is a list of properties of a given network interface
card:
   1. __*network*__ - name of the network the NIC belongs to. The network must be
   a valid definition in an infrastructure networks hash. This definition is
   required.
   2. __*ip*__ - an optional property that defines an IP address in case of
   static IP assignment or a *dhcp* literal if the IP should be assigned by DHCP.
   3. __*cloudinit*__ - an optional boolean flag that indicates to use cloud
   init for a given interface. Please note that only one network interface
   should be flagged to use cloud init in any given node. Should more than one
   interface be flagged to use cloud init, the last one shall be taken into
   consideration and passed to cloud init for further configuration. 
 5. __*disks*__ - an optional property to list additional disks that should
 persist accross deployments. It is of array type. A persistant disk itself
 is described by a so-called disk hash with following keywords:
   1. __*name*__ - disk name. It is required.
   2. __*pool*__ - the name of the storage pool the disk should be looked for
  and/or allocated from. This property is required.
   3. __*size*__ - the name size of the disk in megabytes (when the value has a
  suffix *M*) or gigabytes (when the value has a suffix *G*).
 6. __*credentials*__ - an optional property to define credentials for root
 user. This information is passed to cloud init. Following data can be
 specified:
   1. __*root_password*__ - super user password that is set for cloud init
   phase,
   2. __*root_ssh_keys*__ - an array of OpenSSH public keys that are recorded
   into `/root/.ssh/authorized_keys` by cloud init.

The example bellow shows a specification for a database backend and a web node:
```yaml
nodes:
  mgt01.example.com:
    infrastructure: management
    infrastructure_properties:
      affinity_groups:
	    - clu-lab1ch-ag_1
		- clu-lab1ch-ag_3
      keep_ha: true
      datacenter: lab1ch
      cluster: clu-lab1ch
    image: rhel6cloudinit
    interfaces:
      eth0:
        network: dhcp
		cloudinit: true
	credentials:
	  root_password: a_password
	  root_ssh_keys:
	    - OpenSSH key 1
		- OpenSSH key 2
  
  mysql01.example.com:
    infrastructure: lamp
    infrastructure_properties:
      keep_ha: true
    image: rhel6cloudinit
    flavor: medium
    interfaces:
      eth0:
        network: management
        ip: 192.168.253.25
		cloudinit: true
      eth1:
        network: production
        ip: 192.168.1.102
    disks:
      - name: rdo
        pool: storage_pool1
        size: 4000M
      - name: db1
        pool: storage_pool1
        size: 20G

  web01.example.com:
    infrastructure: lamp
    infrastructure_properties:
      keep_ha: false
	  datacenter: lab1ch
	  cluster: clu-lab1ch
    image: rhel6
    flavor: small
    interfaces:
      eth0:
        network: management
        ip: 192.168.253.26
      eth1:
        network: production
        ip: dhcp
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

## Plan

This hash contains some basic settings for the plan. Currently there is only one setting supported

### max_in_flight
The amount of nodes DOP will be executing commands on in parallel.

```yaml
plan:
    max_in_flight: 2
```

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

This can either be a list of nodes or the keyword "all" which will include all nodes for the step.

### roles

This will include all the nodes with a certain role to a step.

roles and nodes can be mixed, dop_common will simply merge the list of nodes. However there has to be at least one node in every step.

### command

The command can either be directly a plugin name if no parameters are needed or a command hash which will be passed to the plugin. The only fixed variable here is the **plugin** variable. The rest of the variables in the command hash depends on the plugin in use and how it will parse the hash.

For more documentation about the plugins and the variables available for configuring them, check the DOPi documentation.


# Examples

For a complete example plan file see:
[DOP Plan Format v 0.0.1 Example](examples/example_deploment_plan_v0.0.1.yaml)

