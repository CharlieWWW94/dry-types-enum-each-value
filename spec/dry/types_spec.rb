# frozen_string_literal: true

RSpec.describe Dry::Types do
  describe ".loader" do
    it "can eagerly load this library" do
      Dry::Types.loader.eager_load
    ensure
      Dry::Types.loader.unload
      Dry::Types.loader.setup
    end
  end

  describe ".register" do
    it "registers a new type constructor" do
      module Test
        module FlatArray
          def self.constructor(input)
            input.flatten
          end
        end
      end

      custom_array = Dry::Types::Nominal.new(Array).constructor(Test::FlatArray.method(:constructor))

      input = [[1], [2]]

      expect(custom_array[input]).to eql([1, 2])
    end
  end

  describe ".[]" do
    before do
      module Test
        class Foo < Dry::Types::Nominal
          def self.[](value)
            value
          end
        end
      end
    end

    let(:unregistered_type) { Test::Foo }

    it 'returns registered type for "string"' do
      expect(Dry::Types["nominal.string"]).to be_a(Dry::Types::Nominal)
      expect(Dry::Types["nominal.string"].name).to eql("String")
    end

    it "caches dynamically built types" do
      expect(Dry::Types["array<string>"]).to be(Dry::Types["array<string>"])
    end

    it "returns unregistered types back" do
      expect(Dry::Types[unregistered_type]).to be(unregistered_type)
    end

    it "has strict types as default in optional namespace" do
      expect(Dry::Types["optional.string"]).to eql(Dry::Types["string"].optional)
    end
  end

  describe "missing constant" do
    it "raises a nice error when a constant like Coercible or Strict is missing" do
      expect {
        Dry::Types::Strict::String
      }.to raise_error(NameError, /dry-types does not define constants for default types/)
    end
  end

  describe ".define_builder" do
    it "adds a new builder method" do
      Dry::Types.define_builder(:or_nil) { |type| type.optional.fallback(nil) }
      constructed = Dry::Types["integer"].or_nil

      expect(constructed.("123")).to be_nil
    ensure
      Dry::Types::Builder.remove_method(:or_nil)
    end

    it "has support for arguments" do
      Dry::Types.define_builder(:or) { |type, fallback| type.fallback(fallback) }
      constructed = Dry::Types["integer"].or(300)

      expect(constructed.("123")).to eql(300)
    ensure
      Dry::Types::Builder.remove_method(:or)
    end
  end
end
