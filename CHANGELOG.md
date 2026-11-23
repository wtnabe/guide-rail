## [0.2.6] - 2026-11-23

No change in the code from 0.2.5. Only README, CHANGELOG and the version differ in the package.

- README: add techniques of `computed`
  - share a method among computed attributes, as a class method of the extending class
  - add or replace values in a nested Hash, by returning a new Hash that replaces the whole attribute
- Restructure tests by schema and input patterns. No change in behavior

## [0.2.5] - 2026-11-22

- Fix `renderable` with `computed` overwriting a nested schema attr. When the computed returns `nil`, the default of the schema shape ( e.g. `{lat: "", lon: ""}` ) is set instead of `""`

## [0.2.4] - 2026-11-22

- Fix syntax and arguments of `sig/guide-rail.rbs`. It could not be parsed by rbs since 0.1.0
  - add `monadic`, which was missing
  - `create_class!` returns `singleton(Data)` ( the class ), not `Data`
  - `Dry::Monads::Result` has no type arguments, since there are no official type definitions of dry-monads

## [0.2.3] - 2026-11-22

- Add `from_collection` to create Data objects from a collection ( each element is validated on its own )
- `from` raises `ArgumentError` for a collection ( raised `TypeError` before )

## [0.2.2] - 2026-11-22

- Add `computed` to define attributes derived from validated input

## [0.2.1] - 2026-11-22

- Move internals to `GuideRail::Factory`. The extending class has only the DSL, `create_class!` and `from` as class methods
- Add the license to the gemspec ( BSD-2-Clause )

## [0.2.0] - 2026-11-21

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
