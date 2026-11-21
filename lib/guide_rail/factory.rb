# frozen_string_literal: true

class GuideRail::Factory
  include Dry::Monads[:result]

  #
  # @param [String|Symbol] klass
  #
  def class_name(klass)
    @_class = klass
  end

  #
  # @param [Dry::Schema::Params|Dry::Schema::Processor] schema
  #
  def schema(schema)
    @_schema = schema
  end

  #
  # @param [bool] bool
  #
  def monadic(bool)
    @_monadic = bool
  end

  #
  # @param [bool] bool
  #
  def renderable(bool)
    @_renderable = bool
  end

  #
  # @param [Proc] block
  #
  def yield_block(&block)
    @_block = block
  end

  #
  # @return [Data]
  #
  def create_class!
    Object.const_get @_class
  rescue NameError
    @_attrs = @_schema.key_map.to_a.map { |k| k.name.to_sym }
    klass = Data.define(*@_attrs, &@_block)
    Object.const_set(@_class, klass)
    klass
  end

  #
  # @param [untyped] data
  # @return [Data|Dry::Schema::Result|Dry::Monads::Result<Data|Dry::Schema::Result>]
  #
  def from(data)
    acceptance = accept(data)
    create_class!
    result = @_schema.call(acceptance)
    Object.const_get @_class

    if result.success?
      values = result.to_h
      new_value = Object.const_get(@_class).new(
        *(
          if @_renderable
            to_renderable(values)
          else
            values
          end
        ).values_at(*@_attrs).map(&:freeze)
      )

      @_monadic ? Success(new_value) : new_value
    else
      @_monadic ? result.to_monad : result
    end
  end

  #
  # @param [untyped] data
  # @return [Hash]
  #
  def accept(data)
    if data.respond_to? :attributes
      # ActiveModel
      data.attributes.transform_keys(&:to_sym)
    elsif data.respond_to? :to_h
      # Struct, OpenStruct, Hashie, etc...
      data.to_h
    elsif data.is_a? Hash
      data
    elsif data.respond_to? :to_hash
      # Hash convertible
      data.to_hash
    end
  end

  #
  # @param [Hash] original
  # @param [Hash] default
  # @return [Hash]
  #
  def to_renderable(original, default = renderable_default)
    default.merge(original) { |key, d_val, o_val|
      o_val.nil? ? d_val : o_val
    }
  end

  #
  # @param [Array] key_map
  # @return [Hash]
  #
  def renderable_default(key_map = @_schema.key_map.dump)
    Hash[*key_map.map { |e|
      case e
      when Hash
        [e.keys.first.to_sym, renderable_default(e.values.first)]
      when String, Symbol
        [e.to_sym, ""]
      end
    }.flatten]
  end
end
