# frozen_string_literal: true

class GuideRail::Factory
  include Dry::Monads[:result]

  #
  # @param [String|Symbol] klass
  #
  def class_name(klass)
    @_class_name = klass
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
  # @param [Symbol] name
  # @param [Proc] block
  #
  def computed(name, &block)
    raise ArgumentError, "computed :#{name} requires a block" unless block

    (@_computeds ||= {})[name.to_sym] = block
  end

  #
  # @return [Data]
  #
  def create_class!
    Object.const_get @_class_name
  rescue NameError
    @_schema_attrs = @_schema.key_map.to_a.map { |k| k.name.to_sym }
    @_acc_class = Data.define(*@_schema_attrs)
    klass = Data.define(*all_member_names, &@_block)
    Object.const_set(@_class_name, klass)
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
    Object.const_get @_class_name

    if result.success?
      values = schema_values(result)
      values.merge!(compute(values))
      values = to_renderable(values, renderable_default.merge(computed_shallow_renderable_default)) if @_renderable

      new_value = Object.const_get(@_class_name).new(*values.values_at(*all_member_names).map(&:freeze))

      @_monadic ? Success(new_value) : new_value
    else
      @_monadic ? result.to_monad : result
    end
  end

  #
  # @param [#to_ary] collection
  # @return [Array<Data|Dry::Schema::Result|Dry::Monads::Result<Data|Dry::Schema::Result>>]
  #
  def from_collection(collection)
    raise ArgumentError, "from_collection accepts a collection ( #to_ary ). Use from for a single input" unless collection.respond_to?(:to_ary)

    collection.to_ary.map { |data| from(data) }
  end

  #
  # @return [Array<Symbol>]
  #
  def all_member_names
    (@_schema_attrs + (@_computeds || {}).keys).uniq
  end

  #
  # Values come from the schema result, so they are coerced by dry-schema
  # ( e.g. "20" -> 20 with Params ). Keys are aligned to the schema attrs
  # ( missing optional keys become nil ) and values are frozen.
  #
  # @param [Dry::Schema::Result] result
  # @return [Hash]
  #
  def schema_values(result)
    values = result.to_h
    @_schema_attrs.to_h { |k| [k, values[k].freeze] }
  end

  #
  # Evaluate each computed block with acc made of validated input and
  # return the results by name.
  #
  # @param [Hash] values
  # @return [Hash]
  #
  def compute(values)
    return {} unless @_computeds

    acc = @_acc_class.new(**values)
    @_computeds.transform_values { |block| block.call(acc).freeze }
  end

  #
  # @return [Hash]
  #
  def computed_shallow_renderable_default
    (@_computeds || {}).keys.to_h { |k| [k, ""] }
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
