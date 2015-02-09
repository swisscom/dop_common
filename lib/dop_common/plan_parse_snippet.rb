
    ## REFACTOR:
    def parse_nodes_hash(raw_nodes_hash)
      parsed_hash = {}
      raw_nodes_hash.each do |node_name, node_hash|
        if node.include? '{i}'
          parse_node_range(node_hash['range']).each do |i|
            node_number = "%0#{node_hash['leading_zeros'] || 3}d" % i
            new_node_name = node_name.gsub('{i}', node_number)
            parsed_hash[new_node_name] = node_hash
          end
        else
          parsed_hash[node_name] = node_hash
        end
      end
    end

    def parse_node_range(raw_node_range)
      Range.new(*raw_node_range.scan(/\d+/)) or
        raise PlanParsingError, 'No valid range defined for node enumeration'
    end


