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

  describe '#symbolize_keys' do
    pending
  end

  describe '#deep_symbolize_keys' do
    pending
  end

  describe '#represents_regexp?' do
    pending
  end

  describe '#is_valid_regexp?' do
    pending
  end

  describe '#pattern_list_valid?' do
    it 'returns true if the hash is correctly specified' do
      hash = {'my_key' => :all}
      expect(DopCommon::HashParser.pattern_list_valid?(hash, 'my_key')).to be(true)
      hash = {'my_key' => 'foo'}
      expect(DopCommon::HashParser.pattern_list_valid?(hash, 'my_key')).to be(true)
      hash = {'my_key' => ['foo', '/foo/']}
      expect(DopCommon::HashParser.pattern_list_valid?(hash, 'my_key')).to be(true)
    end
    it 'returns false if the key is missing but optional' do
      hash = {}
      expect(DopCommon::HashParser.pattern_list_valid?(hash, 'my_key')).to be(false)
    end
    it 'raises an error if the key is missing and not optional' do
      hash = {}
      expect{DopCommon::HashParser.pattern_list_valid?(hash, 'my_key', false)}.to raise_error DopCommon::PlanParsingError
    end
    it 'raises an error if a value in the array is not a string' do
      hash = {'my_key' => [2]}
      expect{DopCommon::HashParser.pattern_list_valid?(hash, 'my_key')}.to raise_error DopCommon::PlanParsingError
    end
    it 'raises an error if a regexp in the array is not valid' do
      hash = {'my_key' => ['/][/']}
      expect{DopCommon::HashParser.pattern_list_valid?(hash, 'my_key')}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#hash_of_pattern_lists_valid?' do
    it 'returns true if the hash is correctly specified' do
      hash = {'my_key' => {'list_1' => '/foo/', 'list_2' => ['foo', '/foo/']}}
      expect(DopCommon::HashParser.hash_of_pattern_lists_valid?(hash, 'my_key')).to be(true)
    end
    it 'returns false if the key is missing but optional' do
      hash = {}
      expect(DopCommon::HashParser.hash_of_pattern_lists_valid?(hash, 'my_key')).to be(false)
    end
    it 'raises an error if the key is missing and not optional' do
      hash = {}
      expect{DopCommon::HashParser.hash_of_pattern_lists_valid?(hash, 'my_key', false)}.to raise_error DopCommon::PlanParsingError
    end
    it 'raises an error if the value is not a hash' do
      hash = {'my_key' => 2}
      expect{DopCommon::HashParser.pattern_list_valid?(hash, 'my_key')}.to raise_error DopCommon::PlanParsingError
    end
    it 'raises an error if a key is not a string' do
      hash = {'my_key' => { 2 => 'foo' }}
      expect{DopCommon::HashParser.pattern_list_valid?(hash, 'my_key')}.to raise_error DopCommon::PlanParsingError
    end
    it 'raises an error if a list is not valid' do
      hash = {'my_key' => { 'list_1' => 2 }}
      expect{DopCommon::HashParser.pattern_list_valid?(hash, 'my_key')}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#parse_pattern_list' do
    pending
  end

  describe '#parse_hash_of_pattern_lists' do
    pending
  end

end
