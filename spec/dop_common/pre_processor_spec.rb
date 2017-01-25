require 'spec_helper'

describe DopCommon::PreProcessor do

  describe '#load_plan' do
    subject{ DopCommon::PreProcessor.load_plan(file) }

    context 'All the include files are present and correct' do
      let(:file) { 'spec/fixtures/simple_include.yaml' }
      it{ is_expected.to be_a String }
      it do
        expect(YAML.load(subject)).to eq({
          'name'          => 'simple_include_test',
          'some_root_key' => 'some_value',
          'some_key'      => ['an_item', 'another_item'],
        })
      end
    end

    context 'Included files are missing' do
      let(:file) { 'spec/fixtures/simple_include_with_errors.yaml' }
      it{ expect{subject}.to raise_error DopCommon::PlanParsingError }
    end
  end

end

