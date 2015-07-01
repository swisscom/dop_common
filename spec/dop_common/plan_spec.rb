require 'spec_helper'

describe DopCommon::Plan do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#name' do
    it 'will return a hash if no name is defined' do
      plan = DopCommon::Plan.new({})
      expect(plan.name).to eq '44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a'
    end
    it 'will return the correct value if name is defined' do
      plan = DopCommon::Plan.new({:name => 'myplan'})
      expect(plan.name).to eq 'myplan'
    end
    it 'will throw and exception if the value is not a String' do
      plan = DopCommon::Plan.new({:name => 2})
      expect{plan.name}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value contais illegal chars' do
      plan = DopCommon::Plan.new({:name => 'my-plan'})
      expect{plan.name}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#max_in_flight' do
    it 'will return the default value if max_in_flight is not defined' do
      plan = DopCommon::Plan.new({})
      expect(plan.max_in_flight).to be DopCommon::Plan::DEFAULT_MAX_IN_FLIGHT
    end
    it 'will return the correct value if max_in_flight is defined' do
      plan = DopCommon::Plan.new({:plan => {:max_in_flight => 10}})
      expect(plan.max_in_flight).to be 10
    end
    it 'will throw and exception if the value is not a Fixnum' do
      plan = DopCommon::Plan.new({:plan => {:max_in_flight => 'foo'}})
      expect{plan.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value is < 1' do
      plan = DopCommon::Plan.new({:plan => {:max_in_flight => -1}})
      expect{plan.max_in_flight}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#ssh_root_pass' do
    it 'will return nil is ssh_root_pass is not defined' do
      plan = DopCommon::Plan.new({})
      expect(plan.ssh_root_pass).to be nil
    end
    it 'will return the correct value if ssh_root_pass is defined' do
      plan = DopCommon::Plan.new({:plan => {:ssh_root_pass => 'mypass'}})
      expect(plan.ssh_root_pass).to eq 'mypass'
    end
    it 'will throw and exception if the value is not a String' do
      plan = DopCommon::Plan.new({:plan => {:ssh_root_pass => 2}})
      expect{plan.ssh_root_pass}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#infrastructures' do
    it 'will throw and exception if the infrastructures key is not defined' do
      plan = DopCommon::Plan.new({})
      expect{plan.infrastructures}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the infrastructures value is not a Hash' do
      plan = DopCommon::Plan.new({:infrastructures => 'foo'})
      expect{plan.infrastructures}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the infrastructures hash is empty' do
      plan = DopCommon::Plan.new({:infrastructures => {}})
      expect{plan.infrastructures}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#nodes' do
    it 'will return a list of nodes' do
      plan = DopCommon::Plan.new({:nodes => {'mynode{i}.example.com' =>{:range  => '1..10', :digits => 3}}})
      expect(plan.nodes.length).to be 10
      expect(plan.nodes[0].name).to eq 'mynode001.example.com'
      expect(plan.nodes[9].name).to eq 'mynode010.example.com'
    end
    it 'will throw and exception if the nodes key is not defined' do
      plan = DopCommon::Plan.new({})
      expect{plan.nodes}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the nodes value is not a Hash' do
      plan = DopCommon::Plan.new({:nodes => 'foo'})
      expect{plan.nodes}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the nodes hash is empty' do
      plan = DopCommon::Plan.new({:nodes => {}})
      expect{plan.nodes}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#steps' do
    it 'will throw and exception if the steps key is not defined' do
      plan = DopCommon::Plan.new({})
      expect{plan.steps}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the value is not an Array' do
      plan = DopCommon::Plan.new({:steps => 'foo'})
      expect{plan.steps}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw and exception if the hash is empty' do
      plan = DopCommon::Plan.new({:steps => []})
      expect{plan.steps}.to raise_error DopCommon::PlanParsingError
    end
  end

end
