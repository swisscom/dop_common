require 'spec_helper'

describe DopCommon::Hooks do
  %w(create update).each do |a|
    %w(pre post).each do |p|
      hook = :"#{p}_#{a}_vm"
      describe "##{hook}" do
        it "will return an empty array if given hook isn't specified" do
          hooks = ::DopCommon::Hooks.new({})
          expect(hooks.send(hook)).to eq([])
        end
        it "will return an array of hooks if specified correctly" do
          hooks = ::DopCommon::Hooks.new({ hook => ['spec/data/fake_hook_file_valid'] })
          expect(hooks.send(hook)).to eq(['spec/data/fake_hook_file_valid'])
        end
        [nil, {}, [], 1].each do |v|
          it "will raise an error if hook isn't specified properly" do
            hooks = ::DopCommon::Hooks.new({ hook => v })
            expect { hooks.send(hook) }.to raise_error ::DopCommon::PlanParsingError
          end
        end
        it "will raise an error if hook isn't a file" do
          hooks = ::DopCommon::Hooks.new({ hook => '/' })
          expect { hooks.send(hook) }.to raise_error ::DopCommon::PlanParsingError
        end
        it "will raise an error if hook isn't an executable file" do
          hooks = ::DopCommon::Hooks.new({ hook => 'spec/data/fake_hook_file_invalid' })
          expect { hooks.send(hook) }.to raise_error ::DopCommon::PlanParsingError
        end
      end
    end
  end
end
