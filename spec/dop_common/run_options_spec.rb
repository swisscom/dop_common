require 'spec_helper'

class RunOptionsTestKlass
  include DopCommon::RunOptions
  def initialize(hash); @hash = hash; end
end

describe DopCommon::RunOptions do

  describe '#max_in_flight' do
    it 'will return nil if max_in_flight is not defined' do
      run_options = RunOptionsTestKlass.new({})
      expect(run_options.max_in_flight).to be nil
    end
    it 'will return the correct value if max_in_flight is defined' do
      run_options = RunOptionsTestKlass.new({:max_in_flight => 10})
      expect(run_options.max_in_flight).to be 10
    end
    it 'will throw and exception if the value is not a Fixnum' do
      run_options = RunOptionsTestKlass.new({:max_in_flight => 'foo'})
      expect{run_options.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value is < -1' do
      run_options = RunOptionsTestKlass.new({:max_in_flight => -2})
      expect{run_options.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#max_per_role' do
    it 'will return nil if max_per_role is not defined' do
      run_options = RunOptionsTestKlass.new({})
      expect(run_options.max_per_role).to be nil
    end
    it 'will return the correct value if max_per_role is defined' do
      run_options = RunOptionsTestKlass.new({:max_per_role => 10})
      expect(run_options.max_per_role).to be 10
    end
    it 'will throw and exception if the value is not a Fixnum' do
      run_options = RunOptionsTestKlass.new({:max_per_role => 'foo'})
      expect{run_options.max_per_role}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value is < -1' do
      run_options = RunOptionsTestKlass.new({:max_per_role => -2})
      expect{run_options.max_per_role}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#canary_host' do
    it 'returns false if the key is missing' do
      run_options = RunOptionsTestKlass.new({})
      expect(run_options.canary_host).to eq false
    end
    it 'returns the correct result if the key is set' do
      run_options = RunOptionsTestKlass.new({:canary_host => true})
      expect(run_options.canary_host).to eq true
      run_options = RunOptionsTestKlass.new({:canary_host => false})
      expect(run_options.canary_host).to eq false
    end
    it 'throws an exception if the value is not a boolean' do
      run_options = RunOptionsTestKlass.new({:canary_host => 'foo'})
      expect{run_options.canary_host}.to raise_error DopCommon::PlanParsingError
    end
  end

end
