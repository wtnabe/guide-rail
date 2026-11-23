# frozen_string_literal: true

require "spec_helper"
require_relative "../patterns"

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

describe GuideRail::Factory do
  describe "#accept" do
    factory = factory_of(creator(Schemas::NAME_REQUIRED))

    it "ActiveModel-like" do
      assert { factory.accept(TestingAmodel.new(name: "a")) == {name: "a"} }
    end

    it "Struct" do
      assert { factory.accept(Struct.new(:name).new(name: "a")) == {name: "a"} }
    end

    it "Hash" do
      assert { factory.accept({name: "a"}) == {name: "a"} }
    end

    it "respond_to? :to_hash" do
      assert { factory.accept(TestingHashable.new) == {name: "a"} }
    end
  end

  describe "#renderable_default" do
    it "nested schema has the nested shape" do
      assert {
        factory_of(creator(Schemas::NESTED_NULLABLE)).renderable_default == {
          addr: "",
          location: {lat: "", lon: ""}
        }
      }
    end

    it "define ( Symbol keys )" do
      assert {
        factory_of(creator(Schemas::STRICT)).renderable_default == {
          age: "",
          name: "",
          location: {lat: ""}
        }
      }
    end

    it "optional key" do
      assert { factory_of(creator(Schemas::NAME_OPTIONAL)).renderable_default == {name: ""} }
    end
  end
end
