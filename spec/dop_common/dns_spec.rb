require 'spec_helper'

describe DopCommon::DNS do
  describe '#name_servers' do
    it "will return list of name servers' IP addresses if specified correctly" do
      dns = DopCommon::DNS.new(nil)
      expect(dns.name_servers).to eq([])
      dns = DopCommon::DNS.new({'name_servers' => ['10.0.1.1', '172.16.2.1']})
      expect(dns.name_servers).to eq(['10.0.1.1', '172.16.2.1'])
    end
    it 'will raise an exception of not specified properly' do
      [nil, {}, [], 'aaa.bbb.ccc', '1.2.3.300'].each do |val|
        dns = DopCommon::DNS.new({'name_servers' => val})
        expect { dns.name_servers }.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#search_domains' do
    it "will return list of search domains if specified correctly" do
      dns = DopCommon::DNS.new(nil)
      expect(dns.search_domains).to eq([])
      dns = DopCommon::DNS.new({'search_domains' => ['foo', 'foo.bar']})
      expect(dns.search_domains).to eq(['foo', 'foo.bar'])
    end
    it 'will raise an exception of not specified properly' do
      [nil, [], {}, '-foo.bar.baz', 'foo.b.c', 'f', 1].each do |val|
        dns = DopCommon::DNS.new({'search_domains' => val})
        expect { dns.search_domains }.to raise_error DopCommon::PlanParsingError
      end
    end
  end
end
