require 'thor'
require 'cloudshaper'

module Cloudshaper
  class CLI < Thor
    class_option 'remote_state', type: 'boolean'
    class_option 'terraform_bin', type: "string", default: 'terraform'

    desc 'list', 'List all available stacks'
    def list
      Cloudshaper::Stacks.stacks.each do |name, _stack|
        puts name
      end
    end

    desc 'show NAME', 'Show details about a stack by name'
    def show(name)
      stack = load_stack(name)
      puts stack
    end

    desc 'plan NAME', 'Show pending changes for a stack'
    def plan(name)
      stack = load_stack(name)
      remote_config(name) if remote_state?
      stack.plan
    end

    desc 'apply NAME', 'Apply all pending stack changes'
    def apply(name)
      stack = load_stack(name)
      stack.apply
      push(name) if remote_state?
    end

    desc 'destroy NAME', 'Destroy a stack'
    def destroy(name)
      stack = load_stack(name)
      stack.destroy
      push(name) if remote_state?
    end

    desc 'pull NAME', 'Pull stack state from remote location'
    def pull(name)
      stack = load_stack(name, pull: false)
      remote_config(name)
      stack.pull
    end

    desc 'push NAME', 'Push stack state from remote location'
    def push(name)
      stack = load_stack(name)
      remote_config(name)
      stack.push
    end

    desc 'remote_config NAME', 'Sets up remote config for a stack'
    def remote_config(name)
      stack = load_stack(name, pull: false)
      stack.remote_config
    end

    option :name, required: true, aliases: '-n'
    option :template, required: true, aliases: '-t'
    option :description,  aliases: '-d'
    option :environment, aliases: '-e'
    desc 'init', 'Initialize a cloudshaper stack'
    def init
      environment = options[:environment] || 'production'
      desc = options[:description] || 'No description given'
      name = options[:name]
      template = options[:template]
      Cloudshaper::Stacks.init(environment, desc, name, template)
      puts "Created stacks.yml, you're ready to configure your stack"
    end

    desc 'uuid', "Generate a UUID for your stacks, so they don't clobber each other"
    def uuid
      puts SecureRandom.uuid
    end

    desc 'version', 'Prints the version of cloudshaper'
    def version
      puts Cloudshaper::VERSION
    end

    private

    def load_stack(stack, pull: true)
      Cloudshaper::Command.terraform_bin = options['terraform_bin']
      Cloudshaper::Stacks.load
      pull(stack) if remote_state? && pull
      stack = Cloudshaper::Stacks.stacks[stack]
      stack.get
      stack
    end

    def remote_state?
      ret = options['remote_state'] == true
    end
  end
end
