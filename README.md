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

Requires Ruby 3.2 or later. CI tests with Ruby 3.2, 3.3, 3.4 and 4.0.

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

Values of the generated Data object come from the schema result, so nested Hashes have only the keys in the schema. With `Dry::Schema.Params`, String keys are accepted and values are coerced:

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

### Nullable Object with `renderable` option

With `renderable`, `nil` and missing optional keys become `""`.

```ruby
SimpleNullableSchema = Dry::Schema.define do
  required(:name).maybe(:string)
  optional(:nickname).filled(:string)
end

class SimpleRenderableCreator
  extend GuideRail

  schema SimpleNullableSchema
  class_name :SimpleRenderable
  renderable true
end

SimpleRenderableCreator.from(name: nil) # => #<data SimpleRenderable name="", nickname="">
SimpleRenderableCreator.from(name: "John", nickname: "Jack") # => #<data SimpleRenderable name="John", nickname="Jack">
SimpleRenderableCreator.from({}) # => #<Dry::Schema::Result{} errors={name: ["is missing"]} path=[]>
```

### Computed attributes

`computed` defines an attribute derived from validated input. The block receives `acc`, which has readers of validated input ( e.g. `acc.first_name` ), and returns the value. A new name adds a member to the generated Data class, and a name that exists in the schema overwrites the value.

`acc` does not contain results of other computed attributes.

```ruby
UserSchema = Dry::Schema.define do
  required(:first_name).filled(:string)
  required(:last_name).filled(:string)
  required(:role).filled(:string)
  required(:status).filled(:string)
end

class UserView
  extend GuideRail

  schema UserSchema
  class_name :User

  computed :display_name do |acc|
    "#{acc.first_name} #{acc.last_name}"
  end

  computed :status do |acc|
    (acc.role == "admin") ? "owner" : acc.status
  end
end

UserView.from(first_name: "Jane", last_name: "Doe", role: "admin", status: "member")
# => #<data User first_name="Jane", last_name="Doe", role="admin", status="owner", display_name="Jane Doe">
```

#### Sharing a method among computed attributes

There is no dedicated DSL for sharing logic, but the block of `computed` is a closure evaluated with `self` as the class that extends GuideRail, so it can call class methods of the class. A class method can be used from multiple computed attributes.

```ruby
GreetingSchema = Dry::Schema.define do
  required(:first_name).filled(:string)
  required(:last_name).filled(:string)
end

class GreetingView
  extend GuideRail

  schema GreetingSchema
  class_name :Greeting

  def self.display_name_of(acc) = "#{acc.first_name} #{acc.last_name}"

  computed :display_name do |acc|
    display_name_of(acc)
  end

  computed :message do |acc|
    "Hello, #{display_name_of(acc)}"
  end
end

GreetingView.from(first_name: "Jane", last_name: "Doe")
# => #<data Greeting first_name="Jane", last_name="Doe", display_name="Jane Doe", message="Hello, Jane Doe">
```

Both are computed attributes, so `renderable`, `to_h`, pattern matching and freezing apply to them. The method runs once per computed that calls it.

If the value does not need to be an attribute, a method in [`yield_block`](#extending-the-data-class) can read other attributes as well. Note that it is not a member ( not in `to_h` or pattern matching ), and with `renderable` it reads the output values ( `""` instead of `nil` ) and its own `nil` is not converted.

#### Adding or replacing values in a nested Hash

Overwriting works for a nested Hash attribute as well. Return a new Hash ( e.g. by `Hash#merge` ) to add a key or replace only some of its values. `acc` itself is not changed.

```ruby
LocationSchema = Dry::Schema.Params do
  required(:addr).filled(:string)
  required(:location).maybe do
    hash do
      required(:lat).maybe(:float)
      required(:lon).maybe(:float)
    end
  end
end

class PlaceView
  extend GuideRail

  schema LocationSchema
  class_name :Place

  computed :location do |acc|
    acc.location&.merge(label: acc.addr, lat: acc.location[:lat]&.round(1))
  end
end

PlaceView.from(addr: "Tokyo", location: {lat: "35.6812", lon: "139.7671"})
# => #<data Place addr="Tokyo", location={lat: 35.7, lon: 139.7671, label: "Tokyo"}>
```

With `renderable`, use 0.2.5 or later. When the computed returns `nil`, the default of the schema shape ( `{lat: "", lon: ""}` ) is set. Before 0.2.5, it was `""`.

### Collection input

`from_collection` applies `from` to each element of a collection ( anything that responds to `to_ary`, e.g. Array ) and returns the results in the same order. Each element succeeds or fails on its own. With `monadic true` ( see [Monadic mode](#monadic-mode) ), each element is a `Dry::Monads::Result`.

```ruby
SimpleNonNullableCreator.from_collection([{name: "John"}, {}])
# => [#<data SimpleNonNullable name="John">, #<Dry::Schema::Result{} errors={name: ["is missing"]} path=[]>]

SimpleNonNullableCreator.from_collection([]) # => []
```

`from` raises `ArgumentError` for a collection, and `from_collection` raises `ArgumentError` for a single input.

### Extending the Data class

`yield_block` gives a block to `Data.define` of the generated class. Use it for what cannot be an attribute, such as methods with arguments.

```ruby
NameSchema = Dry::Schema.define do
  required(:first_name).filled(:string)
  required(:last_name).filled(:string)
end

class NameView
  extend GuideRail

  schema NameSchema
  class_name :Name

  yield_block do
    def full_name(order: :western)
      (order == :eastern) ? "#{last_name} #{first_name}" : "#{first_name} #{last_name}"
    end
  end
end

name = NameView.from(first_name: "Taro", last_name: "Yamada")
name.full_name # => "Taro Yamada"
name.full_name(order: :eastern) # => "Yamada Taro"
```

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
