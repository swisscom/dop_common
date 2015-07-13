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
    it 'throws an exception if the array contains an invalid regexp' do
      step = DopCommon::Step.new({:name => 'foo', :nodes => ['/][/']})
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
    it 'throws an exception if the array contains an invalid regexp' do
      step = DopCommon::Step.new({:name => 'foo', :roles => ['/][/']})
      expect{step.roles}.to raise_error DopCommon::PlanParsingError
    end
  end

  [:nodes_by_config, :exclude_nodes_by_config].each do |method_name|
    describe '#' + method_name.to_s do
      it 'returns a Hash if correctly specified' do
        step = DopCommon::Step.new({:name => 'foo', method_name => {'my_alias' => 'foo'}})
        expect(step.send(method_name)).to eq({'my_alias' => 'foo'})
      end
      it 'returns an empty hash if the key is missing' do
        step = DopCommon::Step.new({:name => 'foo'})
        expect(step.send(method_name)).to eq({})
      end
      it 'throws an exception if the value is something other than a hash' do
        step = DopCommon::Step.new({:name => 'foo', method_name => 1})
        expect{step.send(method_name)}.to raise_error DopCommon::PlanParsingError
      end
      it 'throws an exception if the hash contains something other than a string as a key' do
        step = DopCommon::Step.new({:name => 'foo', method_name => {1 => 'foo'}})
        expect{step.send(method_name)}.to raise_error DopCommon::PlanParsingError
      end
      it 'throws an exception if the hash contains something other than a string as a value' do
        step = DopCommon::Step.new({:name => 'foo', method_name => {'my_alias' => 1}})
        expect{step.send(method_name)}.to raise_error DopCommon::PlanParsingError
      end
      it 'throws an exception if the hash contains an invalid regexp' do
        step = DopCommon::Step.new({:name => 'foo', method_name => {'my_alias' => '/][/'}})
        expect{step.send(method_name)}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#command' do
    it 'returns the command object if a command hash is specified' do
      step = DopCommon::Step.new({:name => 'foo', :command => {:plugin => 'dummy'}})
      expect(step.command).to be_an_instance_of DopCommon::Command
    end
    it 'throws an exception if the command is not specified' do
      step = DopCommon::Step.new({:name => 'foo'})
      expect{step.command}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if the value for command is something other than a String or a Hash' do
      step = DopCommon::Step.new({:name => 'foo', :command => 1})
      expect{step.command}.to raise_error DopCommon::PlanParsingError
    end
  end

end

