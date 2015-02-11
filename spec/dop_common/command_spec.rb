require 'spec_helper'

describe DopCommon::Command do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#plugin' do
    it 'returns the name of the plugin' do
      command = DopCommon::Command.new({:plugin => 'dummy'})
      expect(command.plugin).to eq 'dummy'
      command = DopCommon::Command.new('dummy')
      expect(command.plugin).to eq 'dummy'
    end
    it 'throws an exception if the the plugin name is not correctly specified' do
      command = DopCommon::Command.new(1)
      expect{command.plugin}.to raise_error DopCommon::PlanParsingError
      command = DopCommon::Command.new('')
      expect{command.plugin}.to raise_error DopCommon::PlanParsingError
      command = DopCommon::Command.new({})
      expect{command.plugin}.to raise_error DopCommon::PlanParsingError
      command = DopCommon::Command.new({:plugin => 1})
      expect{command.plugin}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#plugin_timeout' do
    it 'returns the plugin timeout if specified' do
      command = DopCommon::Command.new({:plugin_timeout => 200})
      expect(command.plugin_timeout).to eq 200
    end
    it 'returns the default timeout if nothing is specified' do
      command = DopCommon::Command.new({})
      expect(command.plugin_timeout).to eq 300
    end
    it 'throws an exception if the value is not correctly specified' do
      command = DopCommon::Command.new({:plugin_timeout => 'foo'})
      expect{command.plugin_timeout}.to raise_error DopCommon::PlanParsingError
    end
  end

end

