require 'spec_helper'



describe DopCommon::Validator do

  describe 'valid?' do
    it 'should be valid if the validation returns true' do
      class ValidatorTestKlass
        include DopCommon::Validator
        def validate; true; end
      end
      expect(ValidatorTestKlass.new.valid?).to be true
    end
    it 'should not be valid if the validation returns false' do
      class ValidatorTestKlass
        include DopCommon::Validator
        def validate; set_not_valid; end
      end
      expect(ValidatorTestKlass.new.valid?).to be false
    end
  end

  describe '#log_validation_method' do
    it 'should be valid if the validation methods return true' do
      class ValidatorTestKlass
        include DopCommon::Validator
        def validate; log_validation_method('test_valid?') ; end
        def test_valid?; true; end
      end
      expect(ValidatorTestKlass.new.valid?).to be true
    end
    it 'should be valid if a validation method raises an error' do
      class ValidatorTestKlass
        include DopCommon::Validator
        def validate; log_validation_method('test_valid?') ; end
        def test_valid?; raise DopCommon::PlanParsingError, 'error!'; end
      end
      expect(ValidatorTestKlass.new.valid?).to be false
    end
  end

  describe '#try_validate_obj' do
    pending
  end

end
