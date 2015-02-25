require 'spec_helper'

describe DopCommon::Node do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#range' do
    it 'will return nil if the node is not inflatable' do
      node = DopCommon::Node.new('mynode.example.com', {:range => '1..10'})
      expect(node.range).to be nil
    end
    it 'will return a range object' do
      node = DopCommon::Node.new('mynode{i}.example.com', {:range => '1..10'})
      expect(node.range).to be_an_instance_of Range
    end
    it 'will throw and exception if the key is not defined' do
      node = DopCommon::Node.new('mynode{i}.example.com', {})
      expect{node.range}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw an exception if there are more than two numbers for the range' do
      node = DopCommon::Node.new('mynode{i}.example.com', {:range => '1..10..100'})
      expect{node.range}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw an exception if the first number is bigger than the second' do
      node = DopCommon::Node.new('mynode{i}.example.com', {:range => '10..1'})
      expect{node.range}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#digits' do
    it 'will return the correct number for digits' do
      node = DopCommon::Node.new('mynode{i}.example.com', {})
      expect(node.digits).to be DopCommon::Node::DEFAULT_DIGITS
      node = DopCommon::Node.new('mynode{i}.example.com', {:digits => 10})
      expect(node.digits).to be 10
    end
    it 'will throw an exception if it is lower than 1' do
      node = DopCommon::Node.new('mynode{i}.example.com', {:digits => -1})
      expect{node.digits}.to raise_error DopCommon::PlanParsingError
    end
    it 'will throw an exception if is not a number' do
      node = DopCommon::Node.new('mynode{i}.example.com', {:digits => 'foo'})
      expect{node.digits}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#inflatable?' do
    it 'will return true when the node inflatable' do
      node = DopCommon::Node.new('mynode{i}.example.com', {})
      expect(node.inflatable?).to be true
    end
    it 'will return false when the node is not inflatable' do
      node = DopCommon::Node.new('mynode.example.com', {})
      expect(node.inflatable?).to be false
    end
  end

  describe '#inflate' do
    it 'will return a new array of nodes' do
      node = DopCommon::Node.new('mynode{i}.example.com', {:range => '1..10', :digits => 3})
      nodes = node.inflate
      expect(nodes.length).to be 10
      expect(nodes[0].name).to eq 'mynode001.example.com'
      expect(nodes[9].name).to eq 'mynode010.example.com'
    end
  end


end

