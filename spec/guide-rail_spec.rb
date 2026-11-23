# frozen_string_literal: true

require "spec_helper"
require_relative "patterns"

describe GuideRail do
  describe ".create_class!" do
    klass = creator(Schemas::NAME_REQUIRED).create_class!

    it "is a subclass of Data" do
      assert { klass.superclass == Data }
    end

    it "is named by class_name" do
      assert { klass.to_s == "NameRequired" }
    end
  end

  describe ".from" do
    describe "NAME_REQUIRED" do
      plain = creator(Schemas::NAME_REQUIRED)
      monadic = creator(Schemas::NAME_REQUIRED, monadic: true)

      valid = {name: "a"}
      missing = {}

      it "given String keys, accepts them" do
        assert { plain.from("name" => "a").name == "a" }
      end

      it "given HashWithIndifferentAccess, accepts it" do
        assert { plain.from(ActiveSupport::HashWithIndifferentAccess.new(valid)).name == "a" }
      end

      it "given a collection, raises ArgumentError guiding to from_collection" do
        e = assert_raises(ArgumentError) { plain.from([valid]) }

        assert { e.message.include?("from_collection") }
      end

      describe "plain" do
        it "given valid input, returns Data" do
          data = plain.from(valid)

          assert { data.is_a?(Data) && data.to_h == {name: "a"} }
        end

        it "given invalid input, returns Dry::Schema::Result" do
          assert { plain.from(missing).is_a?(Dry::Schema::Result) }
        end
      end

      describe "monadic" do
        it "given valid input, returns Success" do
          assert { monadic.from(valid).success? }
        end

        it "given invalid input, returns Failure" do
          assert { monadic.from(missing).failure? }
        end
      end
    end

    describe "NAME_NULLABLE" do
      name_nil = {name: nil}

      describe "plain" do
        it "given nil, keeps nil" do
          assert { creator(Schemas::NAME_NULLABLE).from(name_nil).name.nil? }
        end
      end

      describe "renderable" do
        it "given nil, becomes zero length string" do
          assert { creator(Schemas::NAME_NULLABLE, renderable: true).from(name_nil).name == "" }
        end
      end
    end

    describe "NAME_OPTIONAL" do
      describe "renderable" do
        it "given no key, becomes zero length string" do
          assert { creator(Schemas::NAME_OPTIONAL, renderable: true).from({}).name == "" }
        end
      end
    end

    describe "NESTED_NULLABLE" do
      plain = creator(Schemas::NESTED_NULLABLE)
      renderable = creator(Schemas::NESTED_NULLABLE, renderable: true)

      location_nil = {addr: "a", location: nil}
      location_given = {addr: "a", location: {lat: 35.6, lon: 139.7}}

      it "given a Hash, the Hash is frozen" do
        assert_raises(FrozenError) { plain.from(location_given).location[:lat] = 0.0 }
      end

      describe "plain" do
        it "given nil, keeps nil" do
          assert { plain.from(location_nil).location.nil? }
        end
      end

      describe "renderable" do
        it "given non-nil addr, keeps it" do
          assert { renderable.from(location_nil).addr == "a" }
        end

        it "given nil, becomes the default of the schema shape" do
          assert { renderable.from(location_nil).location == {lat: "", lon: ""} }
        end
      end
    end

    describe "COERCING ( Params )" do
      it "given values to coerce, coerces them and drops keys not in schema" do
        data = creator(Schemas::COERCING).from(
          age: "20",
          active: "off",
          score: "",
          born_on: "2026-01-01",
          rate: "1.5",
          ids: ["1", "2"],
          location: {lat: "35.6", extra: 1},
          items: [{n: "1", extra: 1}]
        )

        assert {
          data.to_h == {
            age: 20,
            active: false,
            score: nil,
            born_on: Date.new(2026, 1, 1),
            rate: 1.5,
            ids: [1, 2],
            location: {lat: 35.6},
            items: [{n: 1}]
          }
        }
      end
    end

    describe "STRICT ( define )" do
      plain = creator(Schemas::STRICT)
      renderable = creator(Schemas::STRICT, renderable: true)

      it "given typed values, keeps them as is" do
        assert {
          plain.from(age: 20, name: "", location: {lat: 35.6}).to_h ==
            {age: 20, name: "", location: {lat: 35.6}}
        }
      end

      it "given keys not in schema, drops them" do
        assert { plain.from(age: 20, name: nil, location: {lat: 35.6, extra: 1}).location == {lat: 35.6} }
      end

      it "given a value to coerce, returns Dry::Schema::Result ( no coercion )" do
        assert { plain.from(age: "20", name: nil, location: {lat: 35.6}).is_a?(Dry::Schema::Result) }
      end

      describe "renderable" do
        it "given nil, becomes zero length string" do
          assert { renderable.from(age: 20, name: nil, location: {lat: 35.6}).name == "" }
        end
      end
    end
  end

  describe ".from_collection" do
    plain = creator(Schemas::NAME_REQUIRED)

    with_computed = creator(Schemas::USER) do
      computed :display_name do |acc|
        "#{acc.first_name} #{acc.last_name}"
      end
    end

    it "Array of Data" do
      assert { plain.from_collection([{name: "a"}, {name: "b"}]).map(&:to_h) == [{name: "a"}, {name: "b"}] }
    end

    it "only the failed element is Dry::Schema::Result" do
      results = plain.from_collection([{name: "a"}, {}, {name: "c"}])

      assert { results.map { |r| r.is_a?(Dry::Schema::Result) } == [false, true, false] }
    end

    it "empty" do
      assert { plain.from_collection([]) == [] }
    end

    it "accepts #to_ary" do
      collection = Object.new
      def collection.to_ary = [{name: "a"}]

      assert { plain.from_collection(collection).map(&:name) == ["a"] }
    end

    it "single input raises ArgumentError guiding to from" do
      e = assert_raises(ArgumentError) { plain.from_collection({name: "a"}) }

      assert { e.message.include?("from") }
    end

    it "monadic returns Result for each element" do
      results = creator(Schemas::NAME_REQUIRED, monadic: true).from_collection([{name: "a"}, {}])

      assert { results.map(&:success?) == [true, false] }
      assert { results.first.value!.name == "a" }
    end

    it "renderable applies to each element" do
      assert {
        creator(Schemas::NAME_NULLABLE, renderable: true).from_collection([{name: nil}, {name: "b"}]).map(&:name) ==
          ["", "b"]
      }
    end

    it "computed applies to each element" do
      input = {first_name: "Jane", last_name: "Doe", active: true, role: "admin", status: "member"}

      assert {
        with_computed.from_collection([input, input.merge(first_name: "John")]).map(&:display_name) ==
          ["Jane Doe", "John Doe"]
      }
    end
  end

  describe "class methods of the extending class" do
    overriding = creator(Schemas::NAME_NULLABLE, renderable: true, monadic: true) do
      def self.accept(data) = {}

      def self.to_renderable(original, default = nil) = {}

      def self.renderable_default = {}

      def self.Success(value) = nil
    end

    it "only DSL, create_class!, from and from_collection" do
      assert {
        (Class.new { extend GuideRail }.public_methods - Class.new.public_methods).sort == [
          :class_name, :computed, :create_class!, :from, :from_collection, :monadic, :renderable, :schema, :yield_block
        ]
      }
    end

    it "class methods of the same names as internals do not break from" do
      assert { overriding.from(name: nil).value!.name == "" }
    end
  end

  describe ".yield_block" do
    decorated = creator(Schemas::NAME_OPTIONAL, renderable: true) do
      yield_block do
        alias_method :name_orig, :name
        define_method :name do
          "decorated #{name_orig}"
        end
      end
    end

    it "the block is given to Data.define" do
      assert { decorated.from({}).name == "decorated " }
    end
  end

  describe ".computed" do
    user_view = creator(Schemas::USER) do
      computed :display_name do |acc|
        "#{acc.first_name} #{acc.last_name}"
      end

      computed :status do |acc|
        (acc.active && acc.role == "admin") ? "owner" : acc.status
      end

      computed :observed do |acc|
        {
          status: acc.status,
          writable: acc.respond_to?(:first_name=),
          display_name: acc.respond_to?(:display_name)
        }
      end
    end

    input = {first_name: "Jane", last_name: "Doe", active: true, role: "admin", status: "member"}

    it "members are schema attrs + computed attrs without duplication" do
      assert { user_view.from(input).members == [:first_name, :last_name, :active, :role, :status, :display_name, :observed] }
    end

    it "derives a new attr" do
      assert { user_view.from(input).display_name == "Jane Doe" }
    end

    it "overwrites a schema attr conditionally" do
      assert { user_view.from(input).status == "owner" }
      assert { user_view.from(input.merge(role: "user")).status == "member" }
    end

    describe "acc" do
      observed = user_view.from(input).observed

      it "holds validated input, not overwritten value" do
        assert { observed[:status] == "member" }
      end

      it "has no writer" do
        assert { observed[:writable] == false }
      end

      it "does not contain other computed results" do
        assert { observed[:display_name] == false }
      end
    end

    it "computed value is frozen" do
      assert { user_view.from(input).display_name.frozen? }
    end

    describe "sharing a class method" do
      shared = creator(Schemas::USER) do
        def self.display_name_of(acc) = "#{acc.first_name} #{acc.last_name}"

        computed :display_name do |acc|
          display_name_of(acc)
        end

        computed :message do |acc|
          "Hello, #{display_name_of(acc)}"
        end
      end

      it "block can call class methods of the extending class" do
        assert { shared.from(input).then { |d| [d.display_name, d.message] } == ["Jane Doe", "Hello, Jane Doe"] }
      end
    end

    it "requires a block" do
      assert_raises(ArgumentError) { Class.new { extend GuideRail }.computed(:foo) }
    end

    it "schema failure skips computed" do
      assert { user_view.from({}).is_a?(Dry::Schema::Result) }
    end

    describe "with monadic" do
      monadic = creator(Schemas::USER, monadic: true) do
        computed :display_name do |acc|
          "#{acc.first_name} #{acc.last_name}"
        end
      end

      it "Success carries computed attr" do
        assert { monadic.from(input).value!.display_name == "Jane Doe" }
      end

      it "Failure on schema failure" do
        assert { monadic.from({}).failure? }
      end
    end

    describe "with Params" do
      raw_age = creator(Schemas::AGE) do
        computed :raw_age do |acc|
          acc.age
        end
      end

      it "acc receives coerced values" do
        assert { raw_age.from(age: "20").raw_age == 20 }
      end

      it "acc receives values from String keys" do
        assert { raw_age.from("age" => 20).raw_age == 20 }
      end
    end

    describe "with renderable" do
      raw_name = creator(Schemas::NAME_NULLABLE, renderable: true) do
        computed :raw_name do |acc|
          acc.name
        end

        computed :raw_name_nil do |acc|
          acc.name.nil?
        end

        computed :nickname do |acc|
          nil
        end
      end

      it "acc receives validated input as is, not renderable values" do
        assert { raw_name.from(name: nil).raw_name_nil == true }
      end

      it "renderable applies to computed attrs in output" do
        data = raw_name.from(name: nil)

        assert { data.raw_name == "" && data.nickname == "" }
      end

      it "renderable applies to schema attrs in output" do
        assert { raw_name.from(name: nil).name == "" }
      end

      describe "overwriting a nested schema attr" do
        nested = creator(Schemas::NESTED_NULLABLE, renderable: true) do
          computed :location do |acc|
            acc.location&.merge(label: acc.addr)
          end

          computed :label do |acc|
            nil
          end
        end

        it "nil gets the default of the schema shape" do
          assert { nested.from(addr: nil, location: nil).location == {lat: "", lon: ""} }
        end

        it "new computed attr gets zero length string" do
          assert { nested.from(addr: nil, location: nil).label == "" }
        end
      end
    end
  end
end
