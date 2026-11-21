require "active_model"
require "active_support/hash_with_indifferent_access"

SimpleNonNullableSchema = Dry::Schema.Params do
  required(:name).filled(:string)
end

class SimpleNonNullableCreator
  extend GuideRail

  schema SimpleNonNullableSchema
  class_name :SimpleNonNullable
end

class SimpleNonNullableMonadicCreator
  extend GuideRail

  schema SimpleNonNullableSchema
  class_name :SimpleNonNullableMonadic
  monadic true
end

SimpleNullableSchema = Dry::Schema.Params do
  required(:name).maybe(:string)
end

class SimpleNullableCreator
  extend GuideRail

  schema SimpleNullableSchema
  class_name :SimpleNullable
end

class SimpleRenderableCreator
  extend GuideRail

  schema SimpleNullableSchema
  class_name :SimpleRenderable
  renderable true
end

NestedNonNullableSchema = Dry::Schema.Params do
  required(:addr).filled(:string)
  required(:location).hash do
    required(:lat).filled(:float)
    required(:lon).filled(:float)
  end
end

class NestedNonNullableCreator
  extend GuideRail

  schema NestedNonNullableSchema
  class_name :NestedNonNullable
  renderable true
end

NestedNullableSchema = Dry::Schema.Params do
  required(:addr).maybe(:string)
  required(:location).maybe do
    hash do
      required(:lat).maybe(:float)
      required(:lon).maybe(:float)
    end
  end
end

class NestedNullableCreator
  extend GuideRail

  schema NestedNullableSchema
  class_name :NestedNullable
end

class NestedRenderableCreator
  extend GuideRail

  schema NestedNullableSchema
  class_name :NestedRenderable
  renderable true
end

CoercingSchema = Dry::Schema.Params do
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

class CoercingCreator
  extend GuideRail

  schema CoercingSchema
  class_name :Coercing
end

StrictSchema = Dry::Schema.define do
  required(:age).filled(:integer)
  required(:name).maybe(:string)
  required(:location).hash do
    required(:lat).filled(:float)
  end
end

class StrictCreator
  extend GuideRail

  schema StrictSchema
  class_name :Strict
end

class StrictRenderableCreator
  extend GuideRail

  schema StrictSchema
  class_name :StrictRenderable
  renderable true
end

class OverridingCreator
  extend GuideRail

  schema SimpleNullableSchema
  class_name :Overriding
  renderable true
  monadic true

  def self.accept(data) = {}

  def self.to_renderable(original, default = nil) = {}

  def self.renderable_default = {}

  def self.Success(value) = nil
end

OptionalSchema = Dry::Schema.Params do
  optional(:name).filled(:string)
end

class OptionalAndYieldAccepter
  extend GuideRail

  class_name :ExtendedData
  schema OptionalSchema
  renderable true

  yield_block do
    alias_method :name_orig, :name
    define_method :name do
      "decorated #{name_orig}"
    end
  end
end
