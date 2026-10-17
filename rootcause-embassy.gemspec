# frozen_string_literal: true

# Legacy gem name, same files: installed Gemfiles say
# `gem "rootcause-embassy", github: "rootcause-org/rootcause-embassy-ruby"` and Bundler picks the
# gemspec by name from this checkout. New installs use replypen-embassy.
Gem::Specification.load(File.expand_path("replypen-embassy.gemspec", __dir__)).dup.tap do |spec|
  spec.name = "rootcause-embassy"
end
