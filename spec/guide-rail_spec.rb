# frozen_string_literal: true

require "spec_helper"
require_relative "dummies"

CreationTestingSchema = Dry::Schema.Params do
end

class CreationTester
  extend GuideRail

  schema CreationTestingSchema
  class_name :CreationTesting
end

class GuidedClass
  extend GuideRail
end

class TestingAmodel
  include ActiveModel::API
  include ActiveModel::Attributes

  attribute :name
end

class TestingHashable
  def to_hash
    {name: "a"}
  end
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

describe GuideRail do
  describe ".create_class!" do
    before {
      @klass = CreationTester.create_class!
    }

    it {
      assert { @klass.superclass == Data }
    }

    it {
      assert { @klass.to_s == "CreationTesting" }
    }
  end

  describe ".from" do
    describe "success / failure" do
      describe "pattern match Data class ( default )" do
        it "schema validation failed" do
          assert {
            case SimpleNonNullableCreator.from({})
            when Data
              false
            when Dry::Schema::Result # "else", it's OK
              true
            end
          }
        end

        it "schema validation succeeded" do
          assert {
            case SimpleNonNullableCreator.from(name: "a")
            when Data
              true
            when Dry::Schema::Result # "else", it's OK
              false
            end
          }
        end
      end

      describe "monadic option enabled, return Dry::Monads::Result" do
        it "schema validation failed" do
          assert {
            SimpleNonNullableMonadicCreator.from({}).either(
              ->(e) { false },
              ->(e) { true }
            )
          }
        end

        it "schema validation succeeded" do
          assert {
            SimpleNonNullableMonadicCreator.from(name: "a").either(
              ->(e) { true },
              ->(e) { false }
            )
          }
        end
      end
    end

    describe "value features" do
      it "SimpleNonNullable" do
        assert {
          SimpleNonNullableCreator.from(name: "c").to_h == {name: "c"}
        }
      end

      describe "SimpleNullable" do
        it {
          nullable = SimpleNullableCreator.from(name: nil)

          assert { nullable.name.nil? }
        }
      end

      describe "SimpleRenderable" do
        it {
          renderable = SimpleRenderableCreator.from(name: nil)

          assert { !renderable.name.nil? }
        }
      end

      describe "NestedNullable" do
        it {
          nullable = NestedNullableCreator.from(addr: nil, location: nil)

          assert { nullable.addr.nil? && nullable.location.nil? }
        }
      end

      describe "NestedRenderable" do
        before {
          @renderable = NestedRenderableCreator.from(addr: "a", location: nil)
        }

        it "non-nil is alive, nil is converted to zero length string" do
          assert {
            @renderable.addr == "a" && !@renderable.location.dig(:lat).nil?
          }
        end

        it "Hash value is freezed" do
          assert_raises FrozenError do
            @renderable.location[:lat] = 123.456
          end
        end
      end

      describe "StrictRenderable ( define )" do
        it {
          renderable = StrictRenderableCreator.from(age: 20, name: nil, location: {lat: 35.6})

          assert { renderable.name == "" }
        }
      end
    end

    describe "values come from schema result" do
      describe "Params" do
        before {
          @data = CoercingCreator.from(
            age: "20",
            active: "off",
            score: "",
            born_on: "2026-01-01",
            rate: "1.5",
            ids: ["1", "2"],
            location: {lat: "35.6", extra: 1},
            items: [{n: "1", extra: 1}]
          )
        }

        it { assert { @data.age == 20 } }
        it { assert { @data.active == false } }
        it { assert { @data.score.nil? } }
        it { assert { @data.born_on == Date.new(2026, 1, 1) } }
        it { assert { @data.rate.is_a?(Float) } }
        it { assert { @data.ids == [1, 2] } }
        it { assert { @data.location == {lat: 35.6} } }
        it { assert { @data.items == [{n: 1}] } }

        it "string keys" do
          assert { SimpleNonNullableCreator.from("name" => "a").name == "a" }
        end

        it "HashWithIndifferentAccess" do
          input = ActiveSupport::HashWithIndifferentAccess.new(name: "a")

          assert { SimpleNonNullableCreator.from(input).name == "a" }
        end
      end

      describe "define" do
        it "typed input as is" do
          assert {
            StrictCreator.from(age: 20, name: "", location: {lat: 35.6}).to_h ==
              {age: 20, name: "", location: {lat: 35.6}}
          }
        end

        it "keys not in schema are dropped" do
          assert {
            StrictCreator.from(age: 20, name: nil, location: {lat: 35.6, extra: 1}).location ==
              {lat: 35.6}
          }
        end

        it "no coercion" do
          assert { StrictCreator.from(age: "20", name: nil, location: {lat: 35.6}).is_a? Dry::Schema::Result }
        end
      end
    end
  end

  describe ".accept" do
    it "ActiveModel-like" do
      assert {
        GuidedClass.accept(TestingAmodel.new(name: "a")) == {name: "a"}
      }
    end

    it "Struct, OpenStruct, Hashie, ..." do
      assert {
        GuidedClass.accept(Struct.new(:name).new(name: "a")) == {name: "a"}
      }
    end

    it "Hash" do
      assert {
        GuidedClass.accept({name: "a"}) == {name: "a"}
      }
    end

    it "respond_to? :to_hash" do
      assert {
        GuidedClass.accept(TestingHashable.new) == {name: "a"}
      }
    end
  end

  describe ".renderable_default" do
    describe "NestedRenderable" do
      it {
        assert {
          NestedRenderableCreator.renderable_default == {
            addr: "",
            location: {
              lat: "",
              lon: ""
            }
          }
        }
      }
    end

    describe "define ( Symbol keys )" do
      it {
        assert {
          StrictRenderableCreator.renderable_default == {
            age: "",
            name: "",
            location: {
              lat: ""
            }
          }
        }
      }
    end

    describe "optional" do
      it {
        OptionalAndYieldAccepter.renderable_default == {name: ""}
      }
    end
  end

  describe ".yield_block" do
    it {
      assert {
        OptionalAndYieldAccepter.from({}).name.start_with? "decorated"
      }
    }
  end
end
