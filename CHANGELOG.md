## [Unreleased]

- **Breaking**: values of the generated Data object come from the schema result ( `Dry::Schema::Result#to_h` ) instead of the input
  - with `Dry::Schema.Params`, coerced values are set ( e.g. `"20"` -> `20`, `"off"` -> `false`, `""` -> `nil` for `maybe` )
  - String keys and `HashWithIndifferentAccess` input are accepted with `Dry::Schema.Params` ( set `nil` before )
  - keys not in the schema are dropped, including those in nested Hashes
- Fix `renderable` with `Dry::Schema.define` ( raised `ArgumentError` )
- README examples use `Dry::Schema.define`

## [0.1.0] - 2025-07-05

- Initial release

## [0.0.0] - 2025-06-29

- concept
