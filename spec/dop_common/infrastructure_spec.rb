require 'spec_helper'

describe DopCommon::Infrastructure do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#type' do
    it 'will set and return the type of infrastructure if specified correctly' do
      infrastructure = DopCommon::Infrastructure.new('dummy_infrastructure', {'type' => 'rhev'})
      expect(infrastructure.type).to eq('rhev')
    end
    it 'will raise an error if the type is unspecified and/or invalid' do
      infrastructure = DopCommon::Infrastructure.new('dummy_infrastructure', {})
      expect{infrastructure.type}.to raise_error DopCommon::PlanParsingError
      infrastructure = DopCommon::Infrastructure.new('dummy_infrastructure', {'type' => {:invalid => 'invalid'}})
      expect{infrastructure.type}.to raise_error DopCommon::PlanParsingError
    end
  end
  
  describe '#networks' do
    it 'will set and return the type of infrastructure if specified correctly' do
      infrastructure = DopCommon::Infrastructure.new('dummy_infrastructure', {'type' => 'rhev'})
      expect(infrastructure.type).to eq('rhev')
    end
    it 'will raise an error if the type is unspecified and/or invalid' do
      infrastructure = DopCommon::Infrastructure.new('dummy_infrastructure', {})
      expect{infrastructure.type}.to raise_error DopCommon::PlanParsingError
      infrastructure = DopCommon::Infrastructure.new('dummy_infrastructure', {'type' => {:invalid => 'invalid'}})
      expect{infrastructure.type}.to raise_error DopCommon::PlanParsingError
    end
  end
end

