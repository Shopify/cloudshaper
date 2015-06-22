require 'yaml'

require 'cloudshaper/stack'
require 'cloudshaper/config'

module Cloudshaper
  # Singleton to keep track of stack templates
  class Stacks

    class MalformedConfig < StandardError; end
    class << self
      attr_reader :stacks

      def load
        stacks = Dir["#{Cloudshaper::Config.stacks_dir}/.cloudshaper.*.yml"]
        stacks.each do |stack_config|
          config = YAML.load(File.read(stack_config))
          stack = Cloudshaper::Stack.new(config)
          @stacks[config.name] = stack
        end
      end

      def reset!
        @stacks ||= {}
      end

      def dir
        File.expand_path(File.join(ENV['TERRAFORM_DATA_DIR'] || 'data', 'stacks'))
      end
    end
    reset!
  end
end
