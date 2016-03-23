require 'spec_helper'

describe DopCommon::HashParser do

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
    subject { DopCommon::HashParser.symbolize_keys(
      hash = {'a' => [{'aa' => 1, 'bb' => 2}], 'b' => 3}
    )}
    it { is_expected.to eq({:a => [{'aa' => 1, 'bb' => 2}], :b => 3}) }
  end

  describe '#deep_symbolize_keys' do
    context 'simple nested hash' do
      subject { DopCommon::HashParser.deep_symbolize_keys(
        hash = {'a' => [{'aa' => '1', 'bb' => 2}], 'b' => 3}
      )}
      it { is_expected.to eq({:a => [{:aa => '1', :bb => 2}], :b => 3}) }
    end
    context 'nested hash with loops' do
      subject {
        hash = {'a' => [{'aa' => 1, 'bb' => 2}], 'b' => 3}
        hash['a'] << hash
        DopCommon::HashParser.deep_symbolize_keys(hash)
      }
      it { is_expected.to be_a Hash }
    end
  end

  describe '#represents_regexp?' do
    context 'valid regexp' do
      subject {DopCommon::HashParser.represents_regexp?('/valid/')}
      it { is_expected.to be true }
    end
    context 'invalid regexp' do
      subject {DopCommon::HashParser.represents_regexp?('noregex')}
      it { is_expected.to be false }
    end
  end

  describe '#is_valid_regexp?' do
    context 'valid regexp' do
      subject {DopCommon::HashParser.is_valid_regexp?('/valid/')}
      it { is_expected.to be true }
    end
    context 'invalid regexp' do
      subject {DopCommon::HashParser.is_valid_regexp?('/][/')}
      it { is_expected.to be false }
    end
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

  describe 'load_content' do
    it 'successfully returns the content from a string' do
      value = 'Some simple string'
      expect{DopCommon::HashParser.load_content_valid?(value)}.to_not raise_error
      expect(DopCommon::HashParser.load_content(value)).to eq('Some simple string')
    end

    it 'successfully retrieve content from a file' do
      secret = SecureRandom.hex
      key_file = Tempfile.new('secret_file', ENV['HOME'])
      key_file.write(secret)
      key_file.close
      value = {:file => key_file.path}
      expect{DopCommon::HashParser.load_content_valid?(value)}.to_not raise_error
      expect(DopCommon::HashParser.load_content(value)).to eq(secret)
      key_file.delete
    end

    it 'successfully retrieve content from an executable' do
      secret = SecureRandom.hex
      key_exec = Tempfile.new('secret_exec', ENV['HOME'])
      key_exec.write("#!/bin/sh\necho \"#{secret}\"")
      key_exec.close
      FileUtils.chmod(0700, key_exec.path)
      value = {:exec => [key_exec.path]}
      expect{DopCommon::HashParser.load_content_valid?(value)}.to_not raise_error
      expect(DopCommon::HashParser.load_content(value)).to eq(secret)
      key_exec.delete
    end

    it 'successfully retrieve content from an executable with parameters' do
      secret = SecureRandom.hex
      key_exec = Tempfile.new('secret_exec', ENV['HOME'])
      key_exec.write("#!/bin/sh\necho $2")
      key_exec.close
      FileUtils.chmod(0700, key_exec.path)
      value = {:exec => [key_exec.path, '--secret', secret]}
      expect{DopCommon::HashParser.load_content_valid?(value)}.to_not raise_error
      expect(DopCommon::HashParser.load_content(value)).to eq(secret)
      key_exec.delete
    end

    it "raises an exeption if the file does not exist" do
      file_name = SecureRandom.hex
      value = {:file => File.join('/tmp', file_name)}
      expect{DopCommon::HashParser.load_content_valid?(value)}.to raise_error DopCommon::PlanParsingError
      value = {:exec => File.join('/tmp', file_name)}
      expect{DopCommon::HashParser.load_content_valid?(value)}.to raise_error DopCommon::PlanParsingError
    end
  end

end
