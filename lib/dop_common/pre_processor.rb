#
# This is the plan preprocessor which merges the individual files
# together.
#
require 'yaml'
require 'pathname'

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
          filtered_name = filter_name(line[REGEXP, 1])
          new_file = absolute_filepath(file, filtered_name)
          spacer = ' ' * position
          content += parse_file(new_file).map {|l| spacer + l}
        else
          content << line
        end
      end
      content
    end

    def self.absolute_filepath(file, new_file)
      if Pathname.new(new_file).absolute?
        new_file
      else
        base_dir = Pathname.new(file).expand_path.dirname
        File.join(base_dir, new_file)
      end
    end

    def self.filter_name(file)
      file[/^"(.*)"$/, 1] or
      file[/^'(.*)'$/, 1] or
      file
    end

    def self.validate_file(file)
      File.exist?(file) or
        raise PlanParsingError, "PreProcessor: The included file #{file} does not exist!"
      File.readable?(file) or
        raise PlanParsingError, "PreProcessor: The included file #{file} is not readable!"
    end

  end
end
