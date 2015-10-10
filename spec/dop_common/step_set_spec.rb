require 'spec_helper'

describe DopCommon::StepSet do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#steps' do
    it 'will return an array of steps if correctly specified' do
      step_set = DopCommon::StepSet.new('foo', [{:name => 'foo'}])
      expect(step_set.steps).to be_a Array
      expect(step_set.steps.first).to be_a ::DopCommon::Step
    end
    it 'will raise an error if the array is empty' do
      step_set = DopCommon::StepSet.new('foo', [])
      expect{step_set.steps}.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an error if the array contains something other than hashes' do
      step_set = DopCommon::StepSet.new('foo', [{}, 1])
      expect{step_set.steps}.to raise_error DopCommon::PlanParsingError
    end
  end

end
