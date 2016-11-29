#
# DOP common hooks hash parser
#

module DopCommon
  class Hook
    include Validator
    include HashParser

    def initialize(name, hash)
      @name = name
      @hash = symbolize_keys(hash)
    end

    def validate
      log_validation_method(:pre_create_vm_valid?)
      log_validation_method(:post_create_vm_valid?)
      log_validation_method(:pre_update_vm_valid?)
      log_validation_method(:post_update_vm_valid?)
      log_validation_method(:pre_destroy_vm_valid?)
      log_validation_method(:post_destroy_vm_valid?)
    end

    def pre_create_vm
      @pre_create_vm ||= pre_create_vm_valid? ? @hash[:pre_create_vm] : []
    end

    def post_create_vm
      @post_create_vm ||= post_create_vm_valid? ? @hash[:post_create_vm] : []
    end

    def pre_update_vm
      @pre_update_vm ||= pre_update_vm_valid? ? @hash[:pre_update_vm] : []
    end

    def post_update_vm
      @post_update_vm ||= post_update_vm_valid? ? @hash[:post_update_vm] : []
    end

    def pre_destroy_vm
      @pre_destroy_vm ||= pre_destoy_vm_valid? ? @hash[:pre_destroy_vm] : []
    end

    def post_destroy_vm
      @post_destroy_vm ||= post_destroy_vm_valid? ? @hash[:post_destroy_vm] : []
    end

    private

    def hook_valid?(hook_name)
      return false unless @hash.has_key?(hook_name)
      raise PlanParsingError, "Hook #{hook_name}: hooks must be a non-empty array of strings" if
        !@hash[hook_name].kind_of?(Array) || @hash[hook_name].empty? || !@hash[hook_name].all? { |h| h.kind_of?(String) }
      raise PlanParsingError, "Hook #{hook_name}: a hook must be an executable file" unless
        @hash[hook_name].all? { |h| File.file?(h) && File.executable?(h) }
      true
    end

    def pre_create_vm_valid?
      hook_valid?(:pre_create_vm)
    end

    def post_create_vm_valid?
      hook_valid?(:post_create_vm)
    end

    def pre_update_vm_valid?
      hook_valid?(:pre_update_vm)
    end

    def post_update_vm_valid?
      hook_valid?(:post_update_vm)

    def pre_destroy_vm_valid?
      hook_valid?(:pre_destory_vm)
    end

    def post_destroy_vm_valid?
      hook_valid?(:post_destroy_vm)
    end
    end
  end
end
