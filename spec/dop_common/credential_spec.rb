require 'spec_helper'

describe DopCommon::Credential do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#type' do
    it 'returns the type if specified correcrly' do
      credential = DopCommon::Credential.new('test', {:type => :username_password, :username => 'a', :password => 'b'})
      expect(credential.type).to eq :username_password
    end
    it 'will raise an exception if the type is missing' do
      credential = DopCommon::Credential.new('test', {})
      expect{credential.type}.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an exception if the type is not valid' do
      credential = DopCommon::Credential.new('test', {:type => :non_existing_type})
      expect{credential.type}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#username' do
    it 'returns a username if one is correctly specified' do
      credential = DopCommon::Credential.new('test', {:type => :username_password, :username => 'a', :password => 'b'})
      expect(credential.username).to eq 'a'
    end
    it 'raises an exception if the username is not specified' do
      credential = DopCommon::Credential.new('test', {:type => :username_password, :password => 'b'})
      expect{credential.username}.to raise_error DopCommon::PlanParsingError
    end
    it 'raises an exception if the username is not a string or fixnum' do
      credential = DopCommon::Credential.new('test', {:type => :username_password, :username => [], :password => 'b'})
      expect{credential.username}.to raise_error DopCommon::PlanParsingError
    end
    it 'raises an exception if the type does not support username' do
      credential = DopCommon::Credential.new('test', {:type => :non_existing_type, :username => 'a', :password => 'b'})
      expect{credential.username}.to raise_error StandardError
    end
  end

  describe '#password' do
    it 'returns a password if one is correctly specified' do
      credential = DopCommon::Credential.new('test', {:type => :username_password, :username => 'a', :password => 'b'})
      expect(credential.password).to eq 'b'
    end
    it 'raises an exception if the password is not specified' do
      credential = DopCommon::Credential.new('test', {:type => :username_password, :username => 'a'})
      expect{credential.password}.to raise_error DopCommon::PlanParsingError
    end
    it 'raises an exception if the password is not a string, fixnum or hash' do
      credential = DopCommon::Credential.new('test', {:type => :username_password, :username => 'a', :password => []})
      expect{credential.password}.to raise_error DopCommon::PlanParsingError
    end
    it 'raises an exception if the type does not support password' do
      credential = DopCommon::Credential.new('test', {:type => :non_existing_type, :username => 'a', :password => 'b'})
      expect{credential.password}.to raise_error StandardError
    end
  end

end

