module DopCommon
  module Utils

    class DataSize
      include Validator

      KIBIBYTE = 1024.0
      MEBIBYTE = 1048576.0
      GIBIBYTE = 1073741824.0
      KILOBYTE = 1000.0
      MEGABYTE = 1000000.0
      GIGABYTE = 1000000000.0

      def initialize(input)
        @input ||= input
      end

      def validate
        log_validation_method(:input_valid?)
      end

      def size
        @size ||= input_valid? ? create_size : nil
      end
      alias_method :bytes, :size
      alias_method :b, :size

      def kibibytes
        size / KIBIBYTE
      end
      alias_method :k, :kibibytes

      def mebibytes
        size / MEBIBYTE
      end
      alias_method :m, :mebibytes

      def gibibytes
        size / GIBIBYTE
      end
      alias_method :g, :gibibytes

      def kilobytes
        size / KILOBYTE
      end
      alias_method :kb, :kilobytes

      def megabytes
        size / MEGABYTE
      end
      alias_method :mb, :megabytes

      def gigabytes
        size / GIGABYTE
      end
      alias_method :gb, :gigabytes

      def to_s
        size.to_s
      end

      private

      def input_valid?
        raise PlanParsingError, "DataSize: Invalid input '#{@input}'. It must be an integer or string" unless
          [String, Fixnum].include?(@input.class)
        raise PlanParsingError, "DataSize: Invalid input '#{@input}'. It must be greater than zero" if
          @input.kind_of?(Fixnum) && @input < 1
        raise PlanParsingError, "DataSize: Invalid input '#{@input}'. " \
          "It must be a positive number followed by one of K,KB,M,MB,G,GB literals" if
          @input.kind_of?(String) && @input !~  /^(([1-9]\d*)(\.\d+)?|0\.(0*[1-9]\d*))[KMG]B?$/
        true
      end

      def create_size
        if @input.kind_of?(String)
          if @input.index(/K$/)
            s = @input.sub(/K$/, '').to_f * KIBIBYTE
          elsif @input.index(/M$/)
            s = @input.sub(/M$/, '').to_f * MEBIBYTE
          elsif @input.index(/G$/)
            s = @input.sub(/G$/, '').to_f * GIBIBYTE
          elsif @input.index(/KB$/)
            s = @input.sub(/KB$/, '').to_f * KILOBYTE
          elsif @input.index(/MB$/)
            s = @input.sub(/MB$/, '').to_f * MEGABYTE
          elsif @input.index(/GB$/)
            s = @input.sub(/GB$/, '').to_f * GIGABYTE
          else
            s = @input
          end
          @size = s.to_i
        else
          @size = @input
        end
      end
    end
  end
end
