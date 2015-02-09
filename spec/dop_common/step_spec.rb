require 'spec_helper'

describe DopCommon::Step do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#name' do
    it 'returns the name if it is specified correctly' do
      step = DopCommon::Step.new({:name => 'foo'})
      expect(step.name).to eq 'foo'
    end
    it 'throws an exception if the key is missing' do
      step = DopCommon::Step.new({})
      expect{step.name}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#nodes' do
    it 'returns an array with nodes if correctly specified' do
      step = DopCommon::Step.new({:name => 'foo', :nodes => ['foo']})
      expect(step.nodes).to eq ['foo']
    end
    it 'returns an empty array if the key is missing' do
      step = DopCommon::Step.new({:name => 'foo'})
      expect(step.nodes).to eq []
    end
    it 'returns an array with one element if the value is a string' do
      step = DopCommon::Step.new({:name => 'foo', :nodes => 'foo'})
      expect(step.nodes).to eq ['foo']
    end
    it 'throws an exception if the value is something other than an array or a string' do
      step = DopCommon::Step.new({:name => 'foo', :nodes => 1})
      expect{step.nodes}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if the array contains something other than a string' do
      step = DopCommon::Step.new({:name => 'foo', :nodes => ['foo', 1]})
      expect{step.nodes}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#roles' do
    it 'returns an array with roles if correctly specified' do
      step = DopCommon::Step.new({:name => 'foo', :roles => ['foo']})
      expect(step.roles).to eq ['foo']
    end
    it 'returns an empty array if the key is missing' do
      step = DopCommon::Step.new({:name => 'foo'})
      expect(step.roles).to eq []
    end
    it 'returns an array with one element if the value is a string' do
      step = DopCommon::Step.new({:name => 'foo', :roles => 'foo'})
      expect(step.roles).to eq ['foo']
    end
    it 'throws an exception if the value is something other than an array or a string' do
      step = DopCommon::Step.new({:name => 'foo', :roles => 1})
      expect{step.roles}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if the array contains something other than a string' do
      step = DopCommon::Step.new({:name => 'foo', :roles => ['foo', 1]})
      expect{step.roles}.to raise_error DopCommon::PlanParsingError
    end
  end

end

