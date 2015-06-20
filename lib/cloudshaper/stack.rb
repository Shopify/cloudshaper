require 'fileutils'

require 'cloudshaper/stacks'
require 'cloudshaper/command'
require 'cloudshaper/remote'
require 'cloudshaper/template'

module Cloudshaper
  # Wrapper to instantiate a stack from a yaml definition
  class Stack
    DATA_DIR = 'data'

    class MalformedConfig < Exception; end
    class << self
      def load(config)
        fail MalformedConfig, "Configuration malformed at #{config}" unless config.is_a?(Hash)
        fail MalformedConfig, "A name must be specified for the stack #{config}" unless config.key?('name')
        fail MalformedConfig, 'You must specify a uuid. Get one from rake uuid and add it to the config' unless config.key?('uuid')
        new(config)
      end
    end

    attr_reader :name, :description, :data_dir,
                :stack_id, :remote, :variables

    def initialize(stack_config)
      @name = stack_config.fetch('name')
      @uuid = stack_config.fetch('uuid')
      @remote = stack_config['remote'] || {}
      @description = stack_config['description'] || ''
      @variables = stack_config['variables'] || {}
      @variables['cloudshaper_stack_id'] = @stack_id
      @stack_id = "cloudshaper_#{@name}_#{@uuid}"
      @data_dir = File.join((ENV['DATA_DIR'] || DATA_DIR), @stack_id)
      render_template(stack_config)
    end

    def apply
      Command.new(self, :apply).execute
    end

    def destroy
      Command.new(self, :destroy).execute
    end

    def plan
      Command.new(self, :plan).execute
    end

    def get
      Command.new(self, :get).execute
    end

    def show
      Command.new(self, :show).execute
    end

    def pull
      Remote.new(self, :pull).execute
    end

    def push
      Remote.new(self, :pull).execute
    end

    def remote_config
      Remote.new(self, :config).execute
    end

    def to_s
      <<-eos
Name: #{@name}
Description: #{@description}
Stack Directory: #{@stack_dir}
      eos
    end
  private

    def render_template(stack_config)
      template_name = stack_config.fetch('template')
      template_config = stack_config
      template_data = Template.render(template_config, template_name)
      FileUtils.mkdir_p(@data_dir)
      File.open(File.join(@data_dir, "#{template_name}.tf"), 'w') { |f| f.write(template_data) }
    end
  end
end
