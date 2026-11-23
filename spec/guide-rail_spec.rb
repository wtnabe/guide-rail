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

    it "Array guides to from_collection" do
      e = assert_raises(ArgumentError) { SimpleNonNullableCreator.from([{name: "a"}]) }

      assert { e.message.include?("from_collection") }
    end
  end

  describe ".from_collection" do
    it "Array of Data" do
      assert {
        SimpleNonNullableCreator.from_collection([{name: "a"}, {name: "b"}]).map(&:to_h) ==
          [{name: "a"}, {name: "b"}]
      }
    end

    it "only the failed element is Dry::Schema::Result" do
      results = SimpleNonNullableCreator.from_collection([{name: "a"}, {}, {name: "c"}])

      assert { results.map(&:class) == [SimpleNonNullable, Dry::Schema::Result, SimpleNonNullable] }
    end

    it "empty" do
      assert { SimpleNonNullableCreator.from_collection([]) == [] }
    end

    it "accepts #to_ary" do
      collection = Object.new
      def collection.to_ary = [{name: "a"}]

      assert { SimpleNonNullableCreator.from_collection(collection).map(&:name) == ["a"] }
    end

    it "single input guides to from" do
      e = assert_raises(ArgumentError) { SimpleNonNullableCreator.from_collection({name: "a"}) }

      assert { e.message.include?("from") }
    end

    it "monadic returns Result for each element" do
      results = SimpleNonNullableMonadicCreator.from_collection([{name: "a"}, {}])

      assert { results.map(&:success?) == [true, false] }
      assert { results.first.value!.name == "a" }
    end

    it "renderable applies to each element" do
      assert { SimpleRenderableCreator.from_collection([{name: nil}, {name: "b"}]).map(&:name) == ["", "b"] }
    end

    it "computed applies to each element" do
      input = {first_name: "Jane", last_name: "Doe", active: true, role: "admin", status: "member"}

      assert {
        UserView.from_collection([input, input.merge(first_name: "John")]).map(&:display_name) ==
          ["Jane Doe", "John Doe"]
      }
    end
  end

  describe "class methods of the extending class" do
    it "only DSL, create_class!, from and from_collection" do
      assert {
        (Class.new { extend GuideRail }.public_methods - Class.new.public_methods).sort == [
          :class_name, :computed, :create_class!, :from, :from_collection, :monadic, :renderable, :schema, :yield_block
        ]
      }
    end

    it "class methods of the same names as internals do not break from" do
      assert { OverridingCreator.from(name: nil).value!.name == "" }
    end
  end

  describe ".yield_block" do
    it {
      assert {
        OptionalAndYieldAccepter.from({}).name.start_with? "decorated"
      }
    }
  end

  describe ".computed" do
    before {
      @input = {
        first_name: "Jane", last_name: "Doe",
        active: true, role: "admin", status: "member"
      }
    }

    it "members are schema attrs + computed attrs without duplication" do
      assert {
        UserView.from(@input).members == [:first_name, :last_name, :active, :role, :status, :display_name, :observed]
      }
    end

    it "derives a new attr" do
      assert { UserView.from(@input).display_name == "Jane Doe" }
    end

    it "overwrites a schema attr conditionally" do
      assert { UserView.from(@input).status == "owner" }
      assert { UserView.from(@input.merge(role: "user")).status == "member" }
    end

    describe "acc" do
      before {
        @observed = UserView.from(@input).observed
      }

      it "holds validated input, not overwritten value" do
        assert { @observed[:status] == "member" }
      end

      it "has no writer" do
        assert { @observed[:writable] == false }
      end

      it "does not contain other computed results" do
        assert { @observed[:display_name] == false }
      end
    end

    it "computed value is frozen" do
      assert { UserView.from(@input).display_name.frozen? }
    end

    it "block can call class methods of the extending class" do
      assert {
        ComputedSharedLogicCreator.from(@input).then { |d| [d.display_name, d.message] } ==
          ["Jane Doe", "Hello, Jane Doe"]
      }
    end

    it "requires a block" do
      assert_raises(ArgumentError) { Class.new { extend GuideRail }.computed(:foo) }
    end

    it "schema failure skips computed" do
      assert { UserView.from({}).is_a?(Dry::Schema::Result) }
    end

    describe "with monadic" do
      it "Success carries computed attr" do
        assert { UserMonadicView.from(@input).value!.display_name == "Jane Doe" }
      end

      it "Failure on schema failure" do
        assert { UserMonadicView.from({}).failure? }
      end
    end

    describe "with Params" do
      it "acc receives coerced values" do
        assert { ComputedParamsCreator.from(age: "20").raw_age == 20 }
      end

      it "acc receives values from String keys" do
        assert { ComputedParamsCreator.from("age" => 20).raw_age == 20 }
      end
    end

    describe "with renderable" do
      before {
        @renderable = ComputedRenderableCreator.from(name: nil)
      }

      it "acc receives validated input as is, not renderable values" do
        assert { @renderable.raw_name_nil == true }
      end

      it "renderable applies to computed attrs in output" do
        assert { @renderable.raw_name == "" && @renderable.nickname == "" }
      end

      it "renderable applies to schema attrs in output" do
        assert { @renderable.name == "" }
      end

      describe "overwriting a nested schema attr" do
        before {
          @nested = ComputedNestedRenderableCreator.from(addr: nil, location: nil)
        }

        it "nil gets the default of the schema shape" do
          assert { @nested.location == {lat: "", lon: ""} }
        end

        it "new computed attr gets zero length string" do
          assert { @nested.label == "" }
        end
      end
    end
  end
end
