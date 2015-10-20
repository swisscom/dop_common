require 'spec_helper'

class RunOptionsTestKlass
  include DopCommon::RunOptions
  def initialize(hash); @hash = hash; end
end

describe DopCommon::RunOptions do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

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
    ### START DEPRICATED KEY PARSING run_options => max_in_flight
    it 'will return the correct value if max_in_flight is defined' do
      run_options = RunOptionsTestKlass.new({:plan => {:max_in_flight => 10}})
      expect(run_options.max_in_flight).to be 10
    end
    it 'will throw and exception if the value is not a Fixnum' do
      run_options = RunOptionsTestKlass.new({:plan => {:max_in_flight => 'foo'}})
      expect{run_options.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value is < -1' do
      run_options = RunOptionsTestKlass.new({:plan => {:max_in_flight => -2}})
      expect{run_options.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
    ### END DEPRICATED KEY PARSING
  end

  describe '#ssh_root_pass' do
    it 'will return nil is ssh_root_pass is not defined' do
      run_options = RunOptionsTestKlass.new({})
      expect(run_options.ssh_root_pass).to be nil
    end
    it 'will return the correct value if ssh_root_pass is defined' do
      run_options = RunOptionsTestKlass.new({:ssh_root_pass => 'mypass'})
      expect(run_options.ssh_root_pass).to eq 'mypass'
    end
    it 'will throw and exception if the value is not a String' do
      run_options = RunOptionsTestKlass.new({:ssh_root_pass => 2})
      expect{run_options.ssh_root_pass}.to raise_error DopCommon::PlanParsingError
    end
    ### START DEPRICATED KEY PARSING run_options => ssh_root_pass
    it 'will return the correct value if ssh_root_pass is defined' do
      run_options = RunOptionsTestKlass.new({:plan => {:ssh_root_pass => 'mypass'}})
      expect(run_options.ssh_root_pass).to eq 'mypass'
    end
    it 'will throw and exception if the value is not a String' do
      run_options = RunOptionsTestKlass.new({:plan => {:ssh_root_pass => 2}})
      expect{run_options.ssh_root_pass}.to raise_error DopCommon::PlanParsingError
    end
    ### END DEPRICATED KEY PARSING
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
