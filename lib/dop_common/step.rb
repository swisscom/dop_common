#
# DOP common step hash parser
#
module DopCommon
  class Step

    def initialize(hash)
      @hash = hash
    end

    def name
      @name ||= @hash[:name] or
        raise PlanParsingError, "Every step needs to have a 'name' key defined"
    end

    def nodes
      @nodes ||= nodes_valid? ? parse_nodes : []
    end

    def roles
      @roles ||= roles_valid? ? parse_roles : []
    end

    private

    def nodes_valid?
      return false if @hash[:nodes].nil? # nodes is optional
      @hash[:nodes].class == Array || @hash[:nodes].class == String or
        raise PlanParsingError, "Step #{@name}: The value for nodes has to be a string or an array"
      if @hash[:nodes].class == Array
        @hash[:nodes].all?{|n| n.class == String} or
          raise PlanParsingError, "Step #{@name}: The nodes array must only contain strings"
      end
      true
    end

    def parse_nodes
      case @hash[:nodes]
        when String then [ @hash[:nodes] ]
        when Array then @hash[:nodes]
        else []
      end
    end

    def roles_valid?
      return false if @hash[:roles].nil? # roless is optional
      @hash[:roles].class == Array || @hash[:roles].class == String or
        raise PlanParsingError, "Step #{@name}: The value for roless has to be a string or an array"
      if @hash[:roles].class == Array
        @hash[:roles].all?{|n| n.class == String} or
          raise PlanParsingError, "Step #{@name}: The roless array must only contain strings"
      end
      true
    end

    def parse_roles
      case @hash[:roles]
        when String then [ @hash[:roles] ]
        when Array then @hash[:roles]
        else []
      end
    end

  end
end
