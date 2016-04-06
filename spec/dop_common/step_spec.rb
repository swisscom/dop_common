require 'spec_helper'

describe DopCommon::Step do

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


  [:nodes, :exclude_nodes, :roles, :exclude_roles].each do |method_name|
    describe '#' + method_name.to_s do
      it 'returns an array with entries if correctly specified' do
        step = DopCommon::Step.new({:name => 'foo', method_name => ['foo']})
        expect(step.send(method_name)).to eq(['foo'])
      end
      it 'returns an empty array if the key is missing' do
        step = DopCommon::Step.new({:name => 'foo'})
        expect(step.send(method_name)).to eq([])
      end
      it 'returns an array with one element if the value is a string' do
        step = DopCommon::Step.new({:name => 'foo', method_name => 'foo'})
        expect(step.send(method_name)).to eq(['foo'])
      end
      it 'throws an exception if the value is something other than an array or a string' do
        step = DopCommon::Step.new({:name => 'foo', method_name => 1})
        expect{step.send(method_name)}.to raise_error DopCommon::PlanParsingError
      end
      it 'throws an exception if the array contains something other than a string' do
        step = DopCommon::Step.new({:name => 'foo', method_name => ['foo', 1]})
        expect{step.send(method_name)}.to raise_error DopCommon::PlanParsingError
      end
      it 'throws an exception if the array contains an invalid regexp' do
        step = DopCommon::Step.new({:name => 'foo', method_name => ['/][/']})
        expect{step.send(method_name)}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  [:nodes_by_config, :exclude_nodes_by_config].each do |method_name|
    describe '#' + method_name.to_s do
      it 'returns a Hash if correctly specified' do
        step = DopCommon::Step.new({:name => 'foo', method_name => {'my_alias' => 'foo'}})
        expect(step.send(method_name)).to eq({'my_alias' => ['foo']})
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

  describe '#commands' do
    it 'returns the command objects if a command hash is specified' do
      step = DopCommon::Step.new({:name => 'foo', :command => {:plugin => 'dummy'}})
      expect(step.commands).to be_an Array
      expect(step.commands.all?{|c| c.kind_of?(DopCommon::Command)}).to be true
    end
    it 'returns the command objects if a command hash is specified' do
      step = DopCommon::Step.new({:name => 'foo', :commands => [{:plugin => 'dummy'}, 'dummy']})
      expect(step.commands).to be_an Array
      expect(step.commands.all?{|c| c.kind_of?(DopCommon::Command)}).to be true
    end
    it 'throws an exception if the command is not specified' do
      step = DopCommon::Step.new({:name => 'foo'})
      expect{step.commands}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if the value for command is something other than a String or a Hash' do
      step = DopCommon::Step.new({:name => 'foo', :command => 1})
      expect{step.commands}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#set_plugin_defaults' do
    it 'returns an Array if correctly specified (normal plugin string)' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => [{ :plugin => 'ssh/custom', :credentials => 'my_cred'}]})
      expect(step.set_plugin_defaults).to eq([{:plugins => ['ssh/custom'], :credentials => 'my_cred'}])
    end
    it 'returns an Array if correctly specified (plugins :all)' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => [{ :plugins => :all, :credentials => 'my_cred'}]})
      expect(step.set_plugin_defaults).to eq([{:plugins => :all, :credentials => 'my_cred'}])
    end
    it 'returns an Array if correctly specified (plugins array)' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => [{ :plugins => ['ssh/custom', 'ssh/something'], :credentials => 'my_cred'}]})
      expect(step.set_plugin_defaults).to eq([{:plugins => ['ssh/custom', 'ssh/something'], :credentials => 'my_cred'}])
    end
    it 'returns an Array if correctly specified (plugins array)' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => [{ :plugins => '/^ssh/', :credentials => 'my_cred'}]})
      expect(step.set_plugin_defaults).to eq([{:plugins => [Regexp.new('^ssh')], :credentials => 'my_cred'}])
    end
    it 'returns an empty Array if the key is missing' do
      step = DopCommon::Step.new({:name => 'foo'})
      expect(step.set_plugin_defaults).to eq([])
    end
    it 'throws an exception if the value is something other than an array' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => 1})
      expect{step.set_plugin_defaults}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if an entry is not a hash' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => [1]})
      expect{step.set_plugin_defaults}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if no plugins key is present' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => {}})
      expect{step.set_plugin_defaults}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if the plugins value is not valid' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => {:plugins => 1}})
      expect{step.set_plugin_defaults}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if the plugins value is an invalid Regexp' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => {:plugins => '/][/'}})
      expect{step.set_plugin_defaults}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if one of the keys is not a string or symbol' do
      step = DopCommon::Step.new({:name => 'foo', :set_plugin_defaults => {:plugins => 'ssh/custom', 1 => 2}})
      expect{step.set_plugin_defaults}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#delete_plugin_defaults' do
    it 'returns an Array if correctly specified (normal plugin string)' do
      step = DopCommon::Step.new({:name => 'foo', :delete_plugin_defaults => [{:plugin => 'ssh/custom', :delete_keys => ['credentials']}]})
      expect(step.delete_plugin_defaults).to eq([{:plugins => ['ssh/custom'], :delete_keys => ['credentials']}])
    end
    it 'returns an Array if correctly specified (singular)' do
      step = DopCommon::Step.new({:name => 'foo', :delete_plugin_defaults => [{:plugin => 'ssh/custom', :delete_key => 'credentials'}]})
      expect(step.delete_plugin_defaults).to eq([{:plugins => ['ssh/custom'], :delete_keys => ['credentials']}])
    end
    it 'returns an Array if correctly specified (delete all for plugin)' do
      step = DopCommon::Step.new({:name => 'foo', :delete_plugin_defaults => [{:plugin => 'ssh/custom', :delete_keys => :all}]})
      expect(step.delete_plugin_defaults).to eq([{:plugins => ['ssh/custom'], :delete_keys => :all}])
    end
    it 'returns :all if correctly specified (delete all)' do
      step = DopCommon::Step.new({:name => 'foo', :delete_plugin_defaults => :all})
      expect(step.delete_plugin_defaults).to eq(:all)
    end
    it 'returns an empty Array if the key is missing' do
      step = DopCommon::Step.new({:name => 'foo'})
      expect(step.delete_plugin_defaults).to eq([])
    end
    it 'throws an exception if the delete_keys is invalid' do
      step = DopCommon::Step.new({:name => 'foo', :delete_plugin_defaults => [{:plugin => 'ssh/custom', :delete_keys => 2}]})
      expect{step.delete_plugin_defaults}.to raise_error DopCommon::PlanParsingError
    end
    it 'throws an exception if an element in delete_keys is invalid' do
      step = DopCommon::Step.new({:name => 'foo', :delete_plugin_defaults => [{:plugin => 'ssh/custom', :delete_keys => ['foo', 2]}]})
      expect{step.delete_plugin_defaults}.to raise_error DopCommon::PlanParsingError
    end
  end

end

