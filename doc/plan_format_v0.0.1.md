# DOP Plan Format v 0.0.1

## DOP Plan Format

The DOP Plan file consists out of series of hashes and arrays which describe system of nodes that should be created and a list of steps that need to be performed on this nodes in order.

### Infrastructures

TODO: Write the documentation about the infrastructure hash

### Nodes

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


