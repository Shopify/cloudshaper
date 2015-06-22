require 'thor'
require 'cloudshaper'

module Cloudshaper
  module StackHelper
    def load_stack(stack, pull: true)
      Cloudshaper::Command.terraform_bin = options['terraform_bin']
      Cloudshaper::Stacks.load
      pull(stack) if remote_state? && pull
      stack = Cloudshaper::Stacks.stacks[stack]
      stack.get
      stack
    end

  private

    def remote_state?
      ret = options['remote_state'] == true
    end

  end

  class Addon < Thor
    include Cloudshaper::StackHelper

    desc 'add ADDON STACK', 'Adds an addon from a stack'
    def add(addon, stack)
      stack = load_stack(stack)
      stack.add_addon(addon)
    end

    desc 'rm ADDON STACK', 'Removes an addon from a stack'
    def rm(addon, stack)
      stack = load_stack(stack)
      stack.rm_addon(addon)
    end

    desc 'upgrade ADDON STACK', 'Upgrades the tier for an addon for a stack'
    def upgrade(addon, stack)
      stack = load_stack(stack)
      stack.upgrade(addon)
    end

    desc 'downgrade ADDON STACK', 'Downgrades the tier for an addon for a stack'
    def downgrade(addon, stack)
      stack = load_stack(stack)
      stack.downgrade(addon)
    end

  end

  class CLI < Thor
    include Cloudshaper::StackHelper

    class_option 'remote_state', type: 'boolean'
    class_option 'terraform_bin', type: "string", default: 'terraform'

    desc 'addon SUBCOMMAND', 'Manage addons'
    subcommand "addon", Addon

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
      Cloudshaper::Config::Stack.init(environment, desc, name, template)
    end

    desc 'uuid', "Generate a UUID for your stacks, so they don't clobber each other"
    def uuid
      puts SecureRandom.uuid
    end

    desc 'version', 'Prints the version of cloudshaper'
    def version
      puts Cloudshaper::VERSION
    end
  end
end
