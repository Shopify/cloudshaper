require 'yaml'
require 'securerandom'

require 'cloudshaper/stack'

module Cloudshaper
  # Singleton to keep track of stack templates
  class Stacks
    STACK_DIR = Dir.pwd
    class MalformedConfig < StandardError; end
    class << self
      attr_reader :stacks

      def load
        stacks = Dir["#{stacks_dir}/.cloudshaper.*.yml"]
        stacks.each do |stack_config|
          spec = YAML.load(File.read(stack_config))
          stack = Stack.load(spec)
          @stacks[stack.name] = stack
        end
      end

      def init(environment, desc, name, template)
        config = File.join(stacks_dir, ".cloudshaper.#{environment}.yml")
        fail "stack already exists at #{File.expand_path(config)}" if File.exist?(config)
        File.open(config, 'w') do |f|
          f.write(YAML.dump(base_stack_config(desc, name, template)))
        end
        shipit_config(name, environment)
      end

      def base_stack_config(description, name, template)
        {
          'name' => name,
          'uuid' => SecureRandom.uuid,
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
          'procs' => {},
          'addons' => {},
        }
      end

      def shipit_config(name, environment)
        data = <<-eos
deploy:
  override:
    - echo 'noop'
tasks:
  plan:
    action: "Show Plan"
    description: "Shows all planned changes to the infrastructure stack"
    steps:
      - cloudshaper plan #{name} --remote-state
  apply:
    action: "Apply"
    description: "Applies any changes to bring the stack to the desired state"
    steps:
      - cloudshaper apply #{name} --remote-state
        eos
        File.open(File.join(stacks_dir,"shipit.infra_#{environment}.yml"), 'w') { |f| f.write(data)}
      end

      def reset!
        @stacks ||= {}
      end

      def stacks_dir
        ENV['STACK_DIR'] || STACK_DIR
      end

      def dir
        File.expand_path(File.join(ENV['TERRAFORM_DATA_DIR'] || 'data', 'stacks'))
      end
    end
    reset!
  end
end
