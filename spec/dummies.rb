require "active_model"

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
