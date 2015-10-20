require 'spec_helper'

describe DopCommon::Node do
  infrastructures = [
    DopCommon::Infrastructure.new('rhev', {'type' => 'rhev'}),
    DopCommon::Infrastructure.new('rhos', {'type' => 'rhos'}),
    DopCommon::Infrastructure.new('baremetal', {'type' => 'baremetal'})
  ]

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

  describe '#fqdn' do
    it 'will return FQDN is it is syntactically correct' do
      node = DopCommon::Node.new('dummy', {})
      expect(node.fqdn).to eq 'dummy'
      node = DopCommon::Node.new('dummy', { 'fqdn' => 'f.q.dn.' })
      expect(node.fqdn).to eq 'f.q.dn'
    end

    it 'will raise an error if it is not a string' do
      node = DopCommon::Node.new('dummy', { 'fqdn' => :invalid })
      expect{node.fqdn}.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an error if FQDN is too long' do
      node = DopCommon::Node.new('dummy', { 'fqdn' => "#{'long'*300}.f.q.dn" })
      expect{node.fqdn}.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an error if FQDN is syntactically invalid' do
      node = DopCommon::Node.new('dummy', { 'fqdn' => 'invalid.f!.q.dn' })
      expect{node.fqdn}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#image' do
    it 'will return an image of a node' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'image' => 'dummy'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.image).to eq 'dummy'
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'baremetal'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.image).to eq nil
    end

    it 'will raise an error if image is not a string' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'image' => :invalid},
        {:parsed_infrastructures => infrastructures}
      )
      expect{node.image}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#full_clone' do
    it 'will return "true" for OVirt/RHEVm-like provider if unspecified' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.full_clone).to be true
    end
    it 'will return a boolean value if specified properly' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'full_clone' => true},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.full_clone).to be true
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'full_clone' => false},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.full_clone).to be false
    end

    it 'will return the default value in case of invalid provider type' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'baremetal'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.full_clone).to be true
    end
    it 'will raise an error if "full_clone" is of invalid type' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'full_clone' => :invalid},
        {:parsed_infrastructures => infrastructures}
      )
      expect{node.full_clone}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#interfaces' do
    it 'will return an array of interfaces if specified correctly' do
      node = DopCommon::Node.new('foo', {:interfaces => {'eth0' => {}, 'eth1' => {}}})
      expect(node.interfaces.length).to eq 2
      expect(node.interfaces.first.name).to eq 'eth0'
    end
    it 'will return an empty array if interfaces is not specified' do
      node = DopCommon::Node.new('foo', {})
      expect(node.interfaces).to eq([])
    end
    it 'will raise an error if interfaces is not a hash' do
      node = DopCommon::Node.new('foo', {:interfaces => 2})
      expect{node.interfaces}.to raise_error DopCommon::PlanParsingError
    end
     it 'will raise an error if a key in interfaces is not a string' do
      node = DopCommon::Node.new('foo', {:interfaces => {2 => {}}})
      expect{node.interfaces}.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an error if a value in interfaces is not a hash' do
      node = DopCommon::Node.new('foo', {:interfaces => {'eth0' => 2}})
      expect{node.interfaces}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#flavor' do
    it 'will return an empty string if not specified and the provider is other than openstack' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.flavor).to eq ""
    end
    it 'will return "m1.medium" if not specified and the provider is openstack' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhos'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.flavor).to eq 'm1.medium'
    end
    it 'will return the flavor as-is if it is specified and the provider is openstack' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhos', 'flavor' => 'm1.tiny'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.flavor).to eq 'm1.tiny'
    end
    it 'will return flavor name if flavor is specified properly' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'flavor' => 'tiny'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.flavor).to eq 'tiny'
    end
    it 'will raise an error if it is not a string' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'flavor' => :invalid},
        {:parsed_infrastructures => infrastructures}
      )
      expect{node.flavor}.to raise_error DopCommon::PlanParsingError
    end
  end
end
