require 'erb'
require 'ostruct'

require 'cloudshaper/stacks'
require 'cloudshaper/command'
require 'cloudshaper/remote'

module Cloudshaper
  # Wrapper to instantiate a stack from a yaml definition
  class Stack
    TEMPLATE_SOURCE = 'git@github.com/Shopify/terraform-modules//templates'

    class MalformedConfig < Exception; end
    class << self
      def load(config)
        fail MalformedConfig, "Configuration malformed at #{config}" unless config.is_a?(Hash)
        fail MalformedConfig, "A name must be specified for the stack #{config}" unless config.key?('name')
        fail MalformedConfig, 'You must specify a uuid. Get one from rake uuid and add it to the config' unless config.key?('uuid')
        new(config)
      end
    end

    class Template < OpenStruct
      def render(template)
        ERB.new(template).result(binding)
      end
    end

    attr_reader :name, :description, :template,
                :stack_id, :remote, :variables, :body

    def initialize(stack_config)
      @name = stack_config.fetch('name')
      @uuid = stack_config.fetch('uuid')
      @remote = stack_config['remote'] || {}
      @description = stack_config['description'] || ''

      @template = stack_config.fetch('template')
      @variables = stack_config['variables'] || {}
      @config = stack_config['config'] || {}
      @variables['cloudshaper_stack_id'] = @stack_id
      @stack_id = "cloudshaper_#{@name}_#{@uuid}"
      @body = render
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

    # Renders a remote template with local config variables
    def render
      template = File.read(fetch)
      stack_template = Template.new(@config)
      stack_template.render(template)
    end

    # Fetch template from template source
    def fetch
      # source = ENV['TEMPLATE_SOURCE'] || TEMPLATE_SOURCE
      # uri, folder = source.split('//')
      # clone uri to tmpfolder
      # template_path = File.join(tmpfolder, folder, @template)
    end
  end
end
