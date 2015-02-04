require 'spec_helper'

describe DopCommon::Plan do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#max_in_flight' do
    it 'will return the default value if max_in_flight is not defined' do
      plan = DopCommon::Plan.new({})
      expect(plan.max_in_flight).to be DopCommon::Plan::DEFAULT_MAX_IN_FLIGHT
    end
    it 'will return the correct value if max_in_flight is defined' do
      plan = DopCommon::Plan.new({:max_in_flight => 10})
      expect(plan.max_in_flight).to be 10
    end
    it 'will throw and exception if the value is not a Fixnum' do
      plan = DopCommon::Plan.new({:max_in_flight => 'foo'})
      expect{plan.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value is < 1' do
      plan = DopCommon::Plan.new({:max_in_flight => -1})
      expect{plan.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
  end

  [ :infrastructures, :nodes, :steps ].each do |key|
    describe '#' + key.to_s do
      it 'will throw and exception if the key is not defined' do
        plan = DopCommon::Plan.new({})
        expect{plan.send(key.to_s)}.to raise_error DopCommon::PlanParsingError
      end
      it 'will throw and exception if the value is not a Hash' do
        plan = DopCommon::Plan.new({key => 'foo'})
        expect{plan.send(key.to_s)}.to raise_error DopCommon::PlanParsingError
      end
      it 'will throw and exception if the hash is empty' do
        plan = DopCommon::Plan.new({key => {}})
        expect{plan.send(key.to_s)}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

end

