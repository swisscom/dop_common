require 'spec_helper'
require 'yaml'

describe 'Check if all the example plans are valid' do

  before :all do
    DopCommon.log.level = ::Logger::WARN
  end

  Dir['doc/examples/*.yaml'].each do |plan_file|
    describe plan_file do
      it 'will confirm the plan as valid' do
        hash = YAML.load_file(plan_file)
        plan = DopCommon::Plan.new(hash)
        expect(plan.valid?).to be true
      end
    end
  end

end
