# frozen_string_literal: true

require "spec_helper"
require_relative "../dummies"

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

describe GuideRail::Factory do
  #
  # @param [Class] creator
  # @return [GuideRail::Factory]
  #
  def factory_of(creator)
    creator.instance_variable_get(:@_guide_rail_factory)
  end

  describe "#accept" do
    it "ActiveModel-like" do
      assert {
        factory_of(GuidedClass).accept(TestingAmodel.new(name: "a")) == {name: "a"}
      }
    end

    it "Struct, OpenStruct, Hashie, ..." do
      assert {
        factory_of(GuidedClass).accept(Struct.new(:name).new(name: "a")) == {name: "a"}
      }
    end

    it "Hash" do
      assert {
        factory_of(GuidedClass).accept({name: "a"}) == {name: "a"}
      }
    end

    it "respond_to? :to_hash" do
      assert {
        factory_of(GuidedClass).accept(TestingHashable.new) == {name: "a"}
      }
    end
  end

  describe "#renderable_default" do
    describe "NestedRenderable" do
      it {
        assert {
          factory_of(NestedRenderableCreator).renderable_default == {
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
          factory_of(StrictRenderableCreator).renderable_default == {
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
        factory_of(OptionalAndYieldAccepter).renderable_default == {name: ""}
      }
    end
  end
end
