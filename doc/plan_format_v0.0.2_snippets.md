
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



----

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

