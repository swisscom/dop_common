require 'spec_helper'

class SharedOptionsTestKlass
  include DopCommon::SharedOptions
  def initialize(hash); @hash = hash; end
end

describe DopCommon::SharedOptions do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#max_in_flight' do
    it 'will return nil if max_in_flight is not defined' do
      shared_options = SharedOptionsTestKlass.new({})
      expect(shared_options.max_in_flight).to be nil
    end
    it 'will return the correct value if max_in_flight is defined' do
      shared_options = SharedOptionsTestKlass.new({:max_in_flight => 10})
      expect(shared_options.max_in_flight).to be 10
    end
    it 'will throw and exception if the value is not a Fixnum' do
      shared_options = SharedOptionsTestKlass.new({:max_in_flight => 'foo'})
      expect{shared_options.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value is < -1' do
      shared_options = SharedOptionsTestKlass.new({:max_in_flight => -2})
      expect{shared_options.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
    ### START DEPRICATED KEY PARSING shared_options => max_in_flight
    it 'will return the correct value if max_in_flight is defined' do
      shared_options = SharedOptionsTestKlass.new({:plan => {:max_in_flight => 10}})
      expect(shared_options.max_in_flight).to be 10
    end
    it 'will throw and exception if the value is not a Fixnum' do
      shared_options = SharedOptionsTestKlass.new({:plan => {:max_in_flight => 'foo'}})
      expect{shared_options.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value is < -1' do
      shared_options = SharedOptionsTestKlass.new({:plan => {:max_in_flight => -2}})
      expect{shared_options.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
    ### END DEPRICATED KEY PARSING
  end

  describe '#ssh_root_pass' do
    it 'will return nil is ssh_root_pass is not defined' do
      shared_options = SharedOptionsTestKlass.new({})
      expect(shared_options.ssh_root_pass).to be nil
    end
    it 'will return the correct value if ssh_root_pass is defined' do
      shared_options = SharedOptionsTestKlass.new({:ssh_root_pass => 'mypass'})
      expect(shared_options.ssh_root_pass).to eq 'mypass'
    end
    it 'will throw and exception if the value is not a String' do
      shared_options = SharedOptionsTestKlass.new({:ssh_root_pass => 2})
      expect{shared_options.ssh_root_pass}.to raise_error DopCommon::PlanParsingError
    end
    ### START DEPRICATED KEY PARSING shared_options => ssh_root_pass
    it 'will return the correct value if ssh_root_pass is defined' do
      shared_options = SharedOptionsTestKlass.new({:plan => {:ssh_root_pass => 'mypass'}})
      expect(shared_options.ssh_root_pass).to eq 'mypass'
    end
    it 'will throw and exception if the value is not a String' do
      shared_options = SharedOptionsTestKlass.new({:plan => {:ssh_root_pass => 2}})
      expect{shared_options.ssh_root_pass}.to raise_error DopCommon::PlanParsingError
    end
    ### END DEPRICATED KEY PARSING
  end

  describe '#canary_host' do
    it 'returns false if the key is missing' do
      shared_options = SharedOptionsTestKlass.new({})
      expect(shared_options.canary_host).to eq false
    end
    it 'returns the correct result if the key is set' do
      shared_options = SharedOptionsTestKlass.new({:canary_host => true})
      expect(shared_options.canary_host).to eq true
      shared_options = SharedOptionsTestKlass.new({:canary_host => false})
      expect(shared_options.canary_host).to eq false
    end
    it 'throws an exception if the value is not a boolean' do
      shared_options = SharedOptionsTestKlass.new({:canary_host => 'foo'})
      expect{shared_options.canary_host}.to raise_error DopCommon::PlanParsingError
    end
  end


end
