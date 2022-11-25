# frozen_string_literal: true

require_relative 'path'

module TypedParameters
  class Parameter
    attr_accessor :value

    attr_reader :key,
                :schema,
                :parent

    def initialize(key:, value:, schema:, parent: nil)
      @key       = key
      @value     = value
      @schema    = schema
      @parent    = parent
      @validated = false
    end

    def path = @path ||= Path.new(*parent&.path&.keys, *key)

    def keys
      return [] if
        schema.children.blank?

      case value
      when Array
        (0...value.size).to_a
      when Hash
        value.keys
      else
        []
      end
    end

    def validate!
      # TODO(ezekg) Add validations

      @validated = true
    end

    def validated?
      !!validated && ((schema.children.is_a?(Array) && value.all?(&:validated?)) ||
                      (schema.children.is_a?(Hash) && value.all? { |k, v| v.validated? }) ||
                       schema.children.nil?)
    end

    def permitted? = validated?

    def blank? = value.blank?

    def optional? = schema.optional?
    def required? = !optional?

    def delete
      case parent.value
      when Array
        parent.value.delete(self)
      when Hash
        parent.value.delete(
          parent.value.key(self),
        )
      end
    end

    def [](key) = value[key]

    def append(*args, **kwargs) = kwargs.present? ? value.merge!(**kwargs) : value.push(*args)

    def safe
      # TODO(ezekg) Raise if parameter is invalid

      case value
      when Array
        value.map(&:safe)
      when Hash
        value.transform_values(&:safe)
      else
        value
      end
    end

    def unsafe
      case value
      when Array
        value.map(&:unsafe)
      when Hash
        value.transform_values(&:unsafe)
      else
        value
      end
    end

    private

    attr_reader :validated
  end
end