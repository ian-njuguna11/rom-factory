# frozen_string_literal: true

require_relative 'support/coverage'

require 'pathname'
SPEC_ROOT = root = Pathname(__FILE__).dirname

begin
  require 'pry-byebug'
rescue LoadError
  require 'pry'
end

require 'rom-factory'
require 'rspec'

Dir[root.join('support/*.rb').to_s].each do |f|
  require f
end

Dir[root.join('shared/*.rb').to_s].each do |f|
  require f
end

DB_URI = ENV.fetch('DATABASE_URL') do
  if defined? JRUBY_VERSION
    'jdbc:postgresql://localhost/rom_factory'
  else
    'postgres://localhost/rom_factory'
  end
end

warning_api_available = RUBY_VERSION >= '2.4.0'

module SileneceWarnings
  def warn(str)
    if str['/sequel/'] || str['/rspec-core']
      nil
    else
      super
    end
  end
end

module Helpers
  def attribute(type, *args)
    ROM::Factory::Attributes.const_get(type).new(*args)
  end
  ruby2_keywords(:attribute) if respond_to?(:ruby2_keywords, true)

  def value(name, *args)
    attribute(:Value, name, *args)
  end

  def sequence(name, &block)
    attribute(:Sequence, name, &block)
  end

  def callable(name, *args, &block)
    attribute(:Callable, name, *args, nil, block)
  end
end

Warning.extend(SileneceWarnings) if warning_api_available

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = warning_api_available
  config.include(Helpers)
  config.before { ROM::Factory::Sequences.instance.reset }
end
