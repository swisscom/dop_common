require 'spec_helper'

describe DopCommon::Credential do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#type' do
    it 'returns the type if specified correctly (username_password)' do
      credential = DopCommon::Credential.new('test', {:type => :username_password, :username => 'a', :password => 'b'})
      expect(credential.type).to eq :username_password
    end
    it 'returns the type if specified correctly (kerberos)' do
      credential = DopCommon::Credential.new('test', {:type => :kerberos, :realm => 'a',})
      expect(credential.type).to eq :kerberos
    end
    it 'returns the type if specified correctly (ssh_key)' do
      credential = DopCommon::Credential.new('test', {:type => :ssh_key, :username => 'a', :public_key => 'spec/data/fake_keyfile'})
      expect(credential.type).to eq :ssh_key
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

  [:username, :realm, :service, :password].each do |key|
    describe '#' + key.to_s do
      it "returns a #{key} if one is correctly specified" do
        credential = DopCommon::Credential.new('test', {key => 'a'})
        expect(credential.send(key)).to eq 'a'
      end
      it "returns nil if #{key} is not specified" do
        credential = DopCommon::Credential.new('test', {})
        expect(credential.send(key)).to be nil
      end
      it "raises an exception if #{key} is not a string" do
        credential = DopCommon::Credential.new('test', {key => []})
        expect{credential.send(key)}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  [:keytab, :public_key].each do |key|
    describe '#' + key.to_s do
      it "returns the filename if correctly specified" do
        credential = DopCommon::Credential.new('test', {key => 'spec/data/fake_keyfile'})
        expect(credential.send(key)).to eq 'spec/data/fake_keyfile'
      end
      it "returns nil if #{key} is not specified" do
        credential = DopCommon::Credential.new('test', {})
        expect(credential.send(key)).to be nil
      end
      it "raises an exception if the file does not exist" do
        credential = DopCommon::Credential.new('test', {key => 'spec/data/nonexisting_keyfile'})
        expect{credential.send(key)}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

end

