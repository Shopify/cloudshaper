require 'fileutils'

require 'cloudshaper/stacks'
require 'cloudshaper/command'
require 'cloudshaper/remote'
require 'cloudshaper/template'

module Cloudshaper
  # Wrapper to instantiate a stack from a yaml definition
  class Stack
    DATA_DIR = 'data'

    attr_reader :name, :data_dir, :config, :stack_id, :variables

    def initialize(config)
      @config = config
      @stack_id = "cloudshaper_#{@config.name}_#{@config.uuid}"
      @variables = @config.variables
      @variables['cloudshaper_stack_id'] = @stack_id
      @data_dir = File.join((ENV['DATA_DIR'] || DATA_DIR), @stack_id)
      render_template(@config)
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

    def add_addon(addon)
      @config.add_addon(addon)
      @config.save
    end

    def rm_addon(addon)
      @config.rm_addon(addon)
      @config.save
    end

    def upgrade(addon)
      @config.addon(addon).upgrade
      @config.save
    end

    def downgrade(addon)
      @config.addon(addon).downgrade
      @config.save
    end

    def to_s
      <<-eos
Name: #{@config.name}
Description: #{@config.description}
Stack Directory: #{@data_dir}
      eos
    end

  private

    def render_template(config)
      template_name = config.template
      template_config = config
      template_data = Template.render(template_config, template_name)
      FileUtils.mkdir_p(@data_dir)
      File.open(File.join(@data_dir, "#{template_name}.tf"), 'w') { |f| f.write(template_data) }
    end
  end
end
