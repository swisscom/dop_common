#
# DOP common node hash parser
#

module DopCommon
  class Node
    include Validator
    include HashParser

    attr_reader :name

    DEFAULT_DIGITS = 2

    def initialize(name, hash, parent={})
      @name = name
      @hash = symbolize_keys(hash)
      @parsed_infrastructures = parent[:parsed_infrastructures]
    end

    def validate
      log_validation_method('digits_valid?')
      log_validation_method('range_valid?')
      log_validation_method('infrastructure_valid?')
      log_validation_method('image_valid?')
      log_validation_method('interfaces_valid?')
      try_validate_obj("Node: Can't validate the interfaces part because of a previous error"){interfaces}
    end

    def digits
      @digits ||= digits_valid? ?
        @hash[:digits] : DEFAULT_DIGITS
    end

    def range
      @range ||= range_valid? ?
        Range.new(*@hash[:range].scan(/\d+/)) : nil
    end

    # Check if the node describes a series of nodes.
    def inflatable?
      @name.include?('{i}')
    end

    # Create and return all the nodes in the series
    def inflate
      range.map do |node_number|
        @node_copy = clone
        @node_copy.name = @name.gsub('{i}', "%0#{digits}d" % node_number)
        @node_copy
      end
    end

    def infrastructure
      @infrastructure ||= infrastructure_valid? ? create_infrastructure : nil
    end

    def image
      @image ||= image_valid? ? @hash[:image] : nil
    end

    def interfaces
      @interfaces ||= interfaces_valid? ? create_interfaces : []
    end

  protected

    attr_writer :name

  private

    def digits_valid?
      return false unless inflatable?
      return false if @hash[:digits].nil? # digits is optional
      @hash[:digits].kind_of?(Fixnum) or
        raise PlanParsingError, "Node #{@name}: 'digits' has to be a number"
      @hash[:digits] > 0 or
        raise PlanParsingError, "Node #{@name}: 'digits' has to be greater than zero"
    end

    def range_valid?
      if inflatable?
        @hash[:range] or
          raise PlanParsingError, "Node #{@name}: 'range' has to be specified if the node is inflatable"
      else
        return false # range is only needed if inflatable
      end
      @hash[:range].class == String or
        raise PlanParsingError, "Node #{@name}: 'range' has to be a string"
      range_array = @hash[:range].scan(/\d+/)
      range_array and range_array.length == 2 or
        raise PlanParsingError, "Node #{@name}: 'range' has to be a string which contains exactly two numbers"
      range_array[0] < range_array[1] or
        raise PlanParsingError, "Node #{@name}: the first number has to be smaller than the second in 'range'"
    end

    def infrastructure_valid?
      @hash[:infrastructure].kind_of?(String) or
        raise PlanParsingError, "Node #{@name}: The 'infrastructure' pointer must be a string"
      @parsed_infrastructures.find { |i| i.name == @hash[:infrastructure] } or
        raise PlanParsingError, "Node #{@name}: No such infrastructure"
    end

    def image_valid?
      return false if infrastructure.provides?(:baremetal) && @hash[:image].nil?
      raise PlanParsingError, "Node #{@name}: The 'image' must be a string" unless @hash[:image].kind_of?(String)
      true
    end

    def interfaces_valid?
      return false if @hash[:interfaces].nil? # TODO: interfaces should only be optional for baremetal
      @hash[:interfaces].kind_of?(Hash) or
        raise PlanParsingError, "Node #{@name}: The value for 'interfaces' has to be a hash"
      @hash[:interfaces].keys.all?{|i| i.kind_of?(String)} or
        raise PlanParsingError, "Node #{@name}: The keys in the 'interface' hash have to be strings"
      @hash[:interfaces].values.all?{|v| v.kind_of?(Hash)} or
        raise PlanParsingError, "Node #{@name}: The values in the 'interface' hash have to be hashes"
    end

    def create_interfaces
      @hash[:interfaces].map do |interface_name, interface_hash|
        DopCommon::Interface.new(interface_name, interface_hash)
      end
    end

    def create_infrastructure
      @parsed_infrastructures.find { |i| i.name == @hash[:infrastructure] }
    end
  end
end
