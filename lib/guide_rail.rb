# frozen_string_literal: true

require "dry/schema"
require "dry/monads"
require_relative "guide_rail/version"
require_relative "guide_rail/factory"

Dry::Schema.load_extensions(:monads)

#
# Only the DSL, create_class! and from are exposed to the extending class.
# Others live in GuideRail::Factory, one instance per extending class.
#
module GuideRail
  def self.extended(base)
    base.instance_variable_set(:@_guide_rail_factory, Factory.new)
  end

  #
  # @param [String|Symbol] klass
  #
  def class_name(klass)
    @_guide_rail_factory.class_name(klass)
  end

  #
  # @param [Dry::Schema::Params|Dry::Schema::Processor] schema
  #
  def schema(schema)
    @_guide_rail_factory.schema(schema)
  end

  #
  # @param [bool] bool
  #
  def monadic(bool)
    @_guide_rail_factory.monadic(bool)
  end

  #
  # @param [bool] bool
  #
  def renderable(bool)
    @_guide_rail_factory.renderable(bool)
  end

  #
  # @param [Proc] block
  #
  def yield_block(&block)
    @_guide_rail_factory.yield_block(&block)
  end

  #
  # Define a computed attribute derived from validated input.
  # The block receives acc ( read-only accessor of validated input ) and
  # returns the value. Same name as a schema attr overwrites it.
  #
  #   computed :display_name do |acc|
  #     "#{acc.first_name} #{acc.last_name}"
  #   end
  #
  # @param [Symbol] name
  # @param [Proc] block
  #
  def computed(name, &block)
    @_guide_rail_factory.computed(name, &block)
  end

  #
  # @return [Data]
  #
  def create_class!
    @_guide_rail_factory.create_class!
  end

  #
  # Accept an object convertible to Hash ( Hash, Struct, ActiveModel, ... ),
  # validate it with the schema and create a Data object.
  #
  # @param [untyped] data
  # @return [Data|Dry::Schema::Result|Dry::Monads::Result<Data|Dry::Schema::Result>]
  #
  def from(data)
    @_guide_rail_factory.from(data)
  end
end
