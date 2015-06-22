require 'securerandom'

require 'cloudshaper/stacks'

module Cloudshaper
  # Singleton to keep track of stack templates
  module Config
    STACK_DIR = Dir.pwd

    class MalformedConfig < Exception; end

    def self.stacks_dir
      ENV['STACK_DIR'] || STACK_DIR
    end

    class TemplateConfig
      attr_reader :tier, :quantity

      def method_missing(*args)
        nil
      end
    end

    class Addon < TemplateConfig
      def upgrade
        if defined? @tier
          @tier += 1
        else
          @tier = 1
        end
      end

      def downgrade
        if defined? @tier && @tier > 1
          @tier -= 1
        end
      end

    end

    class Formation < TemplateConfig
      def initialize(name)
        @type = name
      end

      def resize(size)
        @quantity = size
      end
    end

    class Stack
      attr_reader :variables, :remote, :name, :uuid, :template, :description

      def initialize(config)
        @name = config.fetch('name')
        @uuid = config.fetch('uuid')
        @type = config.fetch('type')
        @description = config.fetch('description')
        @template = config.fetch('template')
        @remote = config.fetch('remote')
        @environment = config.fetch('environment')
        @variables = config.fetch('variables')

        @formations = config.fetch('formations').inject({}) do |formations, formation_configs|
          formation_configs.each do |name, config|
            formations[name] = ::Formation.new(config)
          end
        end

        @addons = config.fetch('addons').inject({}) do |addons, addon_configs|
          addon_configs.each do |name, config|
            addons[name] = ::Addon.new(config)
          end
        end
      end

      def addon(name)
        @addons.fetch(name)
      end

      def add_addon(addon)
        @addons[addon] = Cloudshaper::Config::Addon.new
      end

      def rm_addon(addon)
        @addons.delete(addon)
      end

      def resize_formation(name, size)
        @formations[name].resize(size)
      end

      def add_formation(name)
        @formations[name] = Cloudshaper::Config::Formation.new(name)
      end

      def rm_formation(name)
        @formations.delete(name)
      end

      def get_binding
        return binding()
      end

      def save
        config = File.join(Cloudshaper::Config.stacks_dir, ".cloudshaper.#{@type}.yml")
        File.open(config, 'w') do |f|
          f.write(YAML.dump(self))
        end
        Cloudshaper::Config::Stack.shipit_config(name, @type)
      end

      def self.init(type, desc, name, template)
        base_config = Cloudshaper::Config::Stack.base_stack_config(type, desc, name, template)
        base = Cloudshaper::Config::Stack.new(base_config)
        base.save
      end

      def self.base_stack_config(type, description, name, template)
        {
          'name' => name,
          'uuid' => SecureRandom.uuid,
          'type' => type,
          'description' => description,
          'template' => template,
          'remote' => {
            's3' => {
              'bucket' => ENV['CLOUDSHAPER_BUCKET'] || 'quartermaster-terraform',
              'region' => ENV['CLOUDSHAPER_BUCKET_REGION'] || 'us-east-1',
            }
          },
          'environment' => {},
          'variables' => {},
          'formations' => {},
          'addons' => {},
        }
      end

      def self.shipit_config(name, environment)
        data = <<-eos
  depl:
    ovride:
      echo 'noop'
  task
    pl:
      tion: "Show Plan"
      scription: "Shows all planned changes to the infrastructure stack"
      eps:
      - cloudshaper plan #{name} --remote-state
    apy:
      tion: "Apply"
      scription: "Applies any changes to bring the stack to the desired state"
      eps:
      - cloudshaper apply #{name} --remote-state
        eos
        File.open(File.join(Cloudshaper::Config.stacks_dir,"shipit.infra_#{environment}.yml"), 'w') { |f| f.write(data)}
      end
    end
  end
end
