# frozen_string_literal: true

require "active_model"
require "active_support/hash_with_indifferent_access"

#
# Patterns of input to test. Each is named by what it has.
#
module Schemas
  NAME_REQUIRED = Dry::Schema.Params do
    required(:name).filled(:string)
  end

  NAME_NULLABLE = Dry::Schema.Params do
    required(:name).maybe(:string)
  end

  NAME_OPTIONAL = Dry::Schema.Params do
    optional(:name).filled(:string)
  end

  AGE = Dry::Schema.Params do
    required(:age).filled(:integer)
  end

  NESTED_NULLABLE = Dry::Schema.Params do
    required(:addr).maybe(:string)
    required(:location).maybe do
      hash do
        required(:lat).maybe(:float)
        required(:lon).maybe(:float)
      end
    end
  end

  COERCING = Dry::Schema.Params do
    required(:age).filled(:integer)
    required(:active).filled(:bool)
    required(:score).maybe(:integer)
    required(:born_on).filled(:date)
    required(:rate).filled(:float)
    required(:ids).array(:integer)
    required(:location).hash do
      required(:lat).filled(:float)
    end
    required(:items).array(:hash) do
      required(:n).filled(:integer)
    end
  end

  STRICT = Dry::Schema.define do
    required(:age).filled(:integer)
    required(:name).maybe(:string)
    required(:location).hash do
      required(:lat).filled(:float)
    end
  end

  USER = Dry::Schema.Params do
    required(:first_name).filled(:string)
    required(:last_name).filled(:string)
    required(:active).filled(:bool)
    required(:role).filled(:string)
    required(:status).filled(:string)
  end
end

#
# Build a creator ( a class extending GuideRail ) of a schema and options.
# A block is evaluated in the creator, for computed, yield_block and so on.
#
# class_name must be unique in the process, since create_class! reuses an
# existing constant. Without a block, creators are cached by the schema and
# options. With a block, call it once in a describe body. The line of the
# block is added to class_name.
#
module CreatorHelper
  CACHE = {}
  NAMES = []

  def creator(pattern, renderable: false, monadic: false, &block)
    key = [pattern, renderable, monadic]
    return CACHE[key] if !block && CACHE.key?(key)

    name = [
      Schemas.constants.find { |c| Schemas.const_get(c).equal?(pattern) }.to_s.split("_").map(&:capitalize).join,
      ("Renderable" if renderable),
      ("Monadic" if monadic),
      ("L#{block.source_location[1]}" if block)
    ].join
    # the constant is set lazily by create_class!, so names are kept here
    raise ArgumentError, "class_name #{name} is already used" if NAMES.include?(name)

    NAMES << name

    klass = Class.new do
      extend GuideRail

      schema pattern
      class_name name
      renderable renderable
      monadic monadic
    end
    klass.class_eval(&block) if block

    block ? klass : (CACHE[key] = klass)
  end

  #
  # @param [Class] creator
  # @return [GuideRail::Factory]
  #
  def factory_of(creator)
    creator.instance_variable_get(:@_guide_rail_factory)
  end
end

Minitest::Spec.extend CreatorHelper
Minitest::Spec.include CreatorHelper
