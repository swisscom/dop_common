# DOP Plan Format v 0.0.1

The DOP Plan file consists out of series of hashes and arrays which describe system of nodes that should be created and a list of steps that need to be performed on this nodes in order.

## Infrastructures

TODO: Write the documentation about the infrastructure hash

## Nodes

The nodes hash holds the basic information about all the nodes you want to create and use. Each entry in the nodes hash is itself a hash. A single entry of this is called a node hash (singular). Each node hash starts with the node name as a key:

```yaml
nodes:
    mysql01.example.com:
        …
```

If you want to create a lot of nodes of the same kind it can be quite repetitive to write them all down individually. Instead you can create multiple nodes in one step:

```yaml
nodes:
    mysql01.example.com:
        …
    web{i}.example.com:
        range: 1..4
        digits: 2
        …
```

This will create a number of nodes in the given range. The string “{i}” will be replaced with the amount of digits given. The above example will create the following nodes:

- mysql01.example.com
- web01.example.com
- web02.example.com
- web03.example.com
- web04.example.com

### Node Properties

TODO: Write the documentation about the node properties

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
       '/web\d+\.example\.com/':
            role: httpd_basic
       web04.example.com:
            role: httpd_special
       '/haproxy\d+\.example\.com/':
            role: haproxy
       '/.example.com/'
            my_other_var: my_other_value
```

You can assign different variables to the same node with different regular expressions, but you can not overwrite the values this way. dop_common will throw an error if two regular expression who match the same node set the same variable. On the other hand you can overwrite a value if you set it with a specific fqdn entry.

The only relevant setting here for DOP is the role variable. The name of the role variable can be configured but defaults to 'role'. If hiera is configured and activated, then dop_common will take the role specified in hiera if found. The hierarchy for the role resolution is as follows:

1. Hiera
2. fqdn match in nodes configuration in Plan file
3. Regular expression match in nodes configuration in Plan file
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
The amount of parallel steps DOP will be executing.

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

