require 'rubygems'
gem 'minitest' # Ensures we are using the gem and not the stdlib
require 'minitest/autorun'
require 'minitest/pride'
require './spec/helpers/extensions/ruby/module'
require 'jekyll_asset_pipeline'

include JekyllAssetPipeline

class MiniTest::Spec
  # Fetch current path
  def current_path
    File.expand_path(File.dirname(__FILE__))
  end

  def source_path
    File.join(File.expand_path(File.dirname(__FILE__)), 'resources', 'source')
  end

  def temp_path
    File.join(File.expand_path(File.dirname(__FILE__)), 'resources', 'temp')
  end

  # Let us use 'context' in specs
  class << self
    alias :context  :describe
  end
end
