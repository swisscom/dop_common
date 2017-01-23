#
# This is the plan preprocessor which merges the individual files
# together.
#
require 'yaml'

module DopCommon
  class PreProcessor

    REGEXP = /(?:^| )include: (\S+)/

    def self.load_plan(file)
      parse_file(file).join
    end

  private

    def self.parse_file(file)
      validate_file(file)
      content = []
      File.readlines(file).each do |line|
        position = (line =~ REGEXP)
        if position
          position += 1 if position > 0
          new_file = line[REGEXP, 1]
          spacer = ' ' * position
          content += parse_file(new_file).map {|l| spacer + l}
        else
          content << line
        end
      end
      content
    end

    def self.validate_file(file)
      File.exist?(file) or
        raise PlanParsingError, "PreProcessor: The included file #{file} does not exist!"
      File.readable?(file) or
        raise PlanParsingError, "PreProcessor: The included file #{file} is not readable!"
    end

  end
end
