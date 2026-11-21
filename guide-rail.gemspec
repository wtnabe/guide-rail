# frozen_string_literal: true

require_relative "lib/guide_rail/version"

Gem::Specification.new do |spec|
  spec.name = "guide-rail"
  spec.version = GuideRail::VERSION
  spec.authors = ["wtnabe"]
  spec.email = ["18510+wtnabe@users.noreply.github.com"]

  spec.summary = "A factory library to create safe, immutable Data objects from various sources using dry-schema and Data ( Ruby 3.2+ )."
  spec.description = "GuideRail transforms various data sources into safe, immutable `Data` objects. By leveraging the robust validation capabilities of `dry-schema`, it provides a clear and declarative way to define, validate, and instantiate your data structures."
  spec.license = "BSD-2-Clause"
  spec.homepage = "https://github.com/wtnabe/guide-rail"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wtnabe/guide-rail"
  spec.metadata["changelog_uri"] = "https://github.com/wtnabe/guide-rail/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "dry-schema"
  spec.add_dependency "dry-monads"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
