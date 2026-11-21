# GuideRail

[![Gem Version](https://badge.fury.io/rb/guide-rail.svg)](https://badge.fury.io/rb/guide-rail)
[![CI](https://github.com/wtnabe/guide-rail/actions/workflows/test.yml/badge.svg)](https://github.com/wtnabe/guide-rail/actions/workflows/test.yml)

**GuideRail** is a opinionated powerful factory library for Ruby that transforms various data sources into safe, immutable `Data` objects. By leveraging the robust validation capabilities of `dry-schema`, it provides a clear and declarative way to define, validate, and instantiate your data structures.

It acts as a "guide rail," ensuring that data flowing into your application (e.g., from controller params or API responses) is valid and conforms to a defined structure before being used in your domain logic or views.

## Key Features

- **Powerful Validation**: Built on top of `dry-schema` for comprehensive data validation and coercion. The generated Data object can be guaranteed to have the expected attribute. ( If you specify required )
- **Immutable Data Objects**: Generates instances of Ruby's native `Data` class, preventing accidental state mutations.
- **Flexible Input**: Accepts various data sources, including Hashes, Structs, and ActiveModel-like objects.
- **Simple and Extendable Factory Class**: A concise and intuitive DSL for defining data factories.
- **View-Friendly Rendering**: An optional `renderable` mode provides `nil`-safe default values, perfect for views.
- **Functional-Programming-Friendly**: An optional `monadic` mode provides integration with functional programming paradigms by returning `Dry::Monads::Result` objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'guide-rail'
```

And then execute:

```bash
$ bundle install
```

or

```bash
$ bundle add guide-rail
```

## Usage

### Most Simple

```ruby
require "guide-rail"

SimpleNonNullableSchema = Dry::Schema.define do
  required(:name).filled(:string)
end

class SimpleNonNullableCreator
  extend GuideRail

  schema SimpleNonNullableSchema
  class_name :SimpleNonNullable
end

SimpleNonNullableCreator.from(name: nil) # => #<Dry::Schema::Result{name: nil} errors={name: ["must be a string"]} path=[]>
SimpleNonNullableCreator.from(name: "John") # => #<data SimpleNonNullable name="John">
SimpleNonNullableCreator.from({}) # => #<Dry::Schema::Result{} errors={name: ["is missing"]} path=[]>
```

### Nullable Object with `renderable` option

```ruby
SimpleNullableSchema = Dry::Schema.define do
  required(:name).maybe(:string)
end

class SimpleRenderableCreator
  extend GuideRail

  schema SimpleNullableSchema
  class_name :SimpleRenderable
  renderable true
end

SimpleRenderableCreator.from(name: nil) # => #<data SimpleRenderable name="">
SimpleRenderableCreator.from(name: "John") # => #<data SimpleRenderable name="John">
SimpleRenderableCreator.from({}) # => #<Dry::Schema::Result{} errors={name: ["is missing"]} path=[]>
```

### extendable Data class

You can give a block to Creator class, the generated Data class can be extended by the block ( applying to `define` class method ).

This can be used to define decorator methods and conversion processes, so the generated Data class can also be used as a so-called ViewModel.

```ruby
OptionalSchema = Dry::Schema.define do
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

OptionalAndYieldAccepter.from({}).name.start_with? "decorated" # => true
```

### Choosing a schema

Values of the generated Data object come from the schema result, not from the input as is. So the Data object has the values the schema validated.

Use `Dry::Schema.define` for typed data such as hand-made Hashes or ActiveModel. Values are not coerced, and the Data object has the input values as is.

Use `Dry::Schema.Params` for HTTP params. String keys are accepted, and values are coerced before validation.

```ruby
AgeSchema = Dry::Schema.Params do
  required(:age).filled(:integer)
end

class AgeCreator
  extend GuideRail

  schema AgeSchema
  class_name :Age
end

AgeCreator.from("age" => "20") # => #<data Age age=20>
```

In both cases, keys not in the schema are dropped, including those in nested Hashes.

### Monadic mode

```ruby
SimpleNonNullableSchema = Dry::Schema.define do
  required(:name).filled(:string)
end

class SimpleNonNullableMonadicCreator
  extend GuideRail

  schema SimpleNonNullableSchema
  class_name :SimpleNonNullableMonadic
  monadic true
end

SimpleNonNullableMonadicCreator.from({}).either(
  ->(e) { e.value! },
  ->(e) { e.errors.to_h }
)
# => {name: ["is missing"]}
```

## Not Implemented

 * i18n support
 * Railtie support
 * Transparent conversion of errors

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wtnabe/guide-rail.
