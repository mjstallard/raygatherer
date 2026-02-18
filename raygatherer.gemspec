# frozen_string_literal: true

require_relative "lib/raygatherer/version"

Gem::Specification.new do |spec|
  spec.name = "raygatherer"
  spec.version = Raygatherer::VERSION
  spec.authors = ["Mike Stallard"]
  spec.email = ["prelate-33.requiem@icloud.com"]

  spec.summary = "CLI for fetching and displaying alerts from Rayhunter"
  spec.description = "Ruby CLI tool for interacting with Rayhunter, a cell tower analysis device " \
                     "for detecting IMSI catchers and other cellular network anomalies. " \
                     "Zero runtime dependencies beyond Ruby stdlib."
  spec.homepage = "https://github.com/mjstallard/raygatherer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mjstallard/raygatherer"
  spec.metadata["changelog_uri"] = "https://github.com/mjstallard/raygatherer/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "webmock", "~> 3.19"
  spec.add_development_dependency "standardrb", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
