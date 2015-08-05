require 'spec_helper'

describe DopCommon::HashParser do

  before :all do
    DopCommon.log.level = ::Logger::FATAL
  end

  describe '#key_aliases' do
    it 'should set the proper keys' do
      hash = {'my_key' => 'test'}
      aliases = ['my_key', :my_keys, 'my_keys']
      DopCommon::HashParser.key_aliases(hash, :my_key, aliases)
      expect(hash[:my_key]).to eq 'test'
      # Make sure we can execute it again
      DopCommon::HashParser.key_aliases(hash, :my_key, aliases)
      expect(hash[:my_key]).to eq 'test'
    end
    it 'raises an exception if more than one alias/key is already set' do
      hash = {'my_key' => 'test', :my_key => 'test2'}
      aliases = ['my_key', :my_keys, 'my_keys']
      expect{DopCommon::HashParser.key_aliases(hash, :my_key, aliases)}.to raise_error DopCommon::PlanParsingError 
    end
  end

end
