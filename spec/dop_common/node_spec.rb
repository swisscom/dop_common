require 'spec_helper'

describe DopCommon::Node do
  infrastructures = [
    DopCommon::Infrastructure.new('rhev', {'type' => 'rhev'}),
    DopCommon::Infrastructure.new('rhos', {'type' => 'rhos'}),
    DopCommon::Infrastructure.new('baremetal', {'type' => 'baremetal'}),
    DopCommon::Infrastructure.new('vsphere', {'type' => 'vsphere'})
  ]

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

  describe '#infrastructure_properties' do
    it 'will return infrastructure properties' do
      node = DopCommon::Node.new(
        'dummy',
        {
          'infrastructure' => 'rhev',
          'infrastructure_properties' => { 'datacenter' => 'foo', 'cluster' => 'bar' }
        },
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.infrastructure_properties).to be_an_instance_of DopCommon::InfrastructureProperties
    end
    it 'will raise an error if infrastructure properties is not hash' do
      node = DopCommon::Node.new(
        'dummy',
        {
          'infrastructure' => 'rhev',
          'infrastructure_properties' => 'foo'
        },
        {:parsed_infrastructures => infrastructures}
      )
      expect{node.infrastructure_properties}.to raise_error DopCommon::PlanParsingError
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
      expect(node.interfaces.all?{|i| i.kind_of?(DopCommon::Interface)}).to be true
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
    it 'will return DEFAULT_OPENSTACK_FLAVOR if not specified and the provider is openstack' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhos'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.flavor).to eq DopCommon::Node::DEFAULT_OPENSTACK_FLAVOR
    end
    it 'will return the flavor as-is if it is specified and the provider is openstack' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhos', 'flavor' => 'anyflavor'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.flavor).to eq 'anyflavor'
    end
    it 'will return the name of the flavor if it exists in VALID_FLAVIR_TYPES and the provider is not openstack' do
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
    it 'will raise an error if infrastructure is not openstack and the flavor is invalid' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'flavor' => 'invalid'},
        {:parsed_infrastructures => infrastructures}
      )
      expect{node.flavor}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#cores' do
    it 'will return number of cores if specified properly' do
      [nil, 1].each do |cores|
        node = DopCommon::Node.new(
          'dummy',
          {'infrastructure' => 'rhev', 'cores' => cores},
          {:parsed_infrastructures => infrastructures}
        )
        expect(node.cores).to eq cores.nil? ? DopCommon::Node::DEFAULT_CORES : cores
      end
    end
    it 'will raise an exception if specified for unallowed provider' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhos', 'cores' => 2},
        {:parsed_infrastructures => infrastructures}
      )
      expect{node.cores}.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an exception in case of invalid input' do
      [:invalid, 'four', '4'].each do |cores|
        node = DopCommon::Node.new(
          'dummy',
          {'infrastructure' => 'rhev', 'cores' => cores},
          {:parsed_infrastructures => infrastructures}
        )
        expect{node.cores}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#memory' do
    it 'will return the memory size in bytes if the specified properly' do
      [nil, '500m', '500M', '10g', '10G'].each do |memory|
        node = DopCommon::Node.new(
          'dummy',
          {'infrastructure' => 'rhev', 'memory' => memory},
          {:parsed_infrastructures => infrastructures}
        )
        expect(node.memory).to eq memory.nil? ? DopCommon::Node::DEFAULT_MEMORY : node.send(:to_bytes, memory)
      end
    end
    it 'will return the memory size in bytes if appropriate flavor is specified' do
      flavor = 'tiny'
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'flavor' => flavor},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.memory).to eq DopCommon::Node::VALID_FLAVOR_TYPES[flavor.to_sym][:memory]
    end
    it 'will return the memory size in bytes defined by flavor if both memory and flavor are used' do
      flavor = 'tiny'
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'flavor' => flavor, 'memory' => '100G'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.memory).to eq DopCommon::Node::VALID_FLAVOR_TYPES[flavor.to_sym][:memory]
    end
    it 'will raise an exception if specified for unallowed provider' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhos', 'memory' => '1G'},
        {:parsed_infrastructures => infrastructures}
      )
      expect{node.memory}.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an exception in case of invalid input' do
      [:invalid, 'invalid', 500].each do |memory|
        node = DopCommon::Node.new(
          'dummy',
          {'infrastructure' => 'rhev', 'memory' => memory},
          {:parsed_infrastructures => infrastructures}
        )
        expect{node.memory}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#storage' do
    it 'will return the storage size in bytes if the specified properly' do
      [nil, '20000m', '20000M', '20g', '20G'].each do |storage|
        node = DopCommon::Node.new(
          'dummy',
          {'infrastructure' => 'rhev', 'storage' => storage},
          {:parsed_infrastructures => infrastructures}
        )
        expect(node.storage).to eq storage.nil? ? DopCommon::Node::DEFAULT_STORAGE : node.send(:to_bytes, storage)
      end
    end
    it 'will return the storage size in bytes if appropriate flavor is specified' do
      flavor = 'tiny'
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'flavor' => flavor},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.storage).to eq DopCommon::Node::VALID_FLAVOR_TYPES[flavor.to_sym][:storage]
    end
    it 'will return the storage size in bytes defined by flavor if both storage and flavor are used' do
      flavor = 'tiny'
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhev', 'flavor' => flavor, 'storage' => '1000G'},
        {:parsed_infrastructures => infrastructures}
      )
      expect(node.storage).to eq DopCommon::Node::VALID_FLAVOR_TYPES[flavor.to_sym][:storage]
    end
    it 'will raise an exception if specified for unallowed provider' do
      node = DopCommon::Node.new(
        'dummy',
        {'infrastructure' => 'rhos', 'storage' => '1G'},
        {:parsed_infrastructures => infrastructures}
      )
      expect{node.storage}.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an exception in case of invalid input' do
      [:invalid, 'invalid', 500].each do |storage|
        node = DopCommon::Node.new(
          'dummy',
          {'infrastructure' => 'rhev', 'storage' => storage},
          {:parsed_infrastructures => infrastructures}
        )
        expect{node.storage}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#timezone' do
    it "will return a parsed 'timezone' property" do
      property_values = {'rhev' => nil, 'vsphere' => '095'}
      property_values.each do |infrastructure, property_val|
        node = DopCommon::Node.new(
          'dummy',
          {'infrastructure' => infrastructure, 'timezone' => property_val },
          {:parsed_infrastructures => infrastructures}
        )
        expect(node.timezone).to eq property_val
      end
    end

    it 'will trow an error if input timezone is invalid' do
      [nil, "", :invalid, []].each do |property_val|
        node = DopCommon::Node.new(
          'dummy',
          {'infrastructure' => 'vsphere', 'timezone' => property_val},
          {:parsed_infrastructures => infrastructures}
        )
        expect{node.timezone}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  %w(product_id organization_name).each do |property_name|
    describe "##{property_name}" do
      it "will return a parsed '#{property_name}' property" do
        ["", nil, "a74230-f3485-84"].each do |property_val|
          next if property_name == "organization_name" && property_val == ""
          node = DopCommon::Node.new(
            'dummy',
            {'infrastructure' => 'vsphere', property_name => property_val }
          )
          expect(node.send(property_name.to_sym)).to eq property_val
        end
      end

      it "will trow an error if #{property_name} format is invalid" do
        ["", :invalid, []].each do |property_val|
          next if property_name == "product_id" && property_val == ""
          node = DopCommon::Node.new(
            'dummy',
            {'infrastructure' => 'vsphere', property_name => property_val}
          )
          expect{node.send(property_name.to_sym)}.to raise_error DopCommon::PlanParsingError
        end
      end
    end
  end

  describe '#credentials' do
    before :all do
      @credentials = {
        'test_up' => DopCommon::Credential.new('test_up', {
          :type     => 'username_password',
          :username => 'alice',
          :password => 'abc123',
        }),
        'test_ssh' => DopCommon::Credential.new('test_ssh', {
          :type       => 'ssh_key',
          :username   => 'bob',
          :public_key => 'spec/fixtures/example_ssh_key.pub',
        }),
        'test_ssh2' => DopCommon::Credential.new('test_ssh2', {
          :type        => 'ssh_key',
          :username    => 'bob',
          :private_key => 'spec/fixtures/example_ssh_key',
        }),
      }
    end

    it 'returns an empty array if nothing is defined' do
      node = DopCommon::Node.new('dummy',{:parsed_credentials => @credentials })
      expect(node.credentials).to be_an Array
      expect(node.credentials.empty?).to be true
    end

    it 'returns an array if a credential if properly defined as a string' do
      node = DopCommon::Node.new('dummy',
        {:credentials => 'test_up'},
        {:parsed_credentials => @credentials }
      )
      expect(node).to have_exactly(1).credentials
      expect(node.credentials.all?{|c| c.kind_of?(DopCommon::Credential)}).to be true
    end

    it 'returns an array if an array of credentials if properly defined' do
      node = DopCommon::Node.new('dummy',
        {:credentials => ['test_up', 'test_ssh']},
        {:parsed_credentials => @credentials }
      )
      expect(node).to have_exactly(2).credentials
      expect(node.credentials.all?{|c| c.kind_of?(DopCommon::Credential)}).to be true
    end

    it 'will throw an error if credentials is not an array or string' do
      node = DopCommon::Node.new('dummy',
        {:credentials => 1},
        {:parsed_credentials => @credentials }
      )
      expect{node.credentials}.to raise_error DopCommon::PlanParsingError
      node = DopCommon::Node.new('dummy',
        {:credentials => ['test_up', 1]},
        {:parsed_credentials => @credentials }
      )
      expect{node.credentials}.to raise_error DopCommon::PlanParsingError
    end

    it 'will throw an error if a node includes a ssh_key credential without public_key' do
      node = DopCommon::Node.new('dummy',
        {:credentials => ['test_up', 'test_ssh2']},
        {:parsed_credentials => @credentials }
      )
      expect{node.credentials}.to raise_error DopCommon::PlanParsingError
    end

  end

  describe '#dns' do
    #before :all do
    #  @dns = {
    #    'valid_name_server'   => { 'name_servers' => ['10.0.2.1'] }
    #    'valid_search_domain' => { 'search_domains' => ['foo.bar'] }
    #    'valid_dns' => { 'name_servers' => ['10.0.2.1', '172.16.0.1']
    #  }
    #end
    it 'returns a dns object if properly defined' do
      [{}, :dns => {:name_servers => ['10.0.1.1'], :search_domains => ['foo.bar']}].each do |dns|
        node = DopCommon::Node.new('dummy', dns)
        expect(node.dns).to be_an_instance_of DopCommon::DNS
      end
    end

    it "will throw an exception if dns object isn't properly defined" do
      [:dns => 'invalid', :dns => nil, :dns => []].each do |dns|
        node = DopCommon::Node.new('dummy', dns)
        expect{node.dns}.to raise_error DopCommon::PlanParsingError
      end
    end
  end
end
