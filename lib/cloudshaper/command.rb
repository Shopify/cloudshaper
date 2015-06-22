require 'cloudshaper/secrets'

module Cloudshaper
  # Wraps terraform command execution
  class Command

    def self.terraform_bin=(path)
      @@terraform_bin = path
    end

    attr_accessor :command

    def initialize(stack, command)
      @stack = stack
      @command = options_for(command)
    end

    def env
      environment = {}
      SECRETS.each do |type, secrets|
        case type
        when 'providers'
          secrets.each do |provider, vars|
            vars.each do |k, v|
              environment[k.to_s] = v
            end
          end
        when 'variables'
          secrets.each do |key, value|
            @stack.variables[key.to_s] = v
          end
        end
      end
      @stack.variables.each { |k, v| environment["TF_VAR_#{k.to_s}"] = v.to_s }
      environment
    end

    def execute
      Process.waitpid(spawn(env, @command))
      fail 'Command failed' unless $?.exitstatus == 0
    end

    protected

    def options_for(cmd)
      options = begin
        case cmd
        when :apply
          '-input=false'
        when :destroy
          '-input=false -force'
        when :plan
          '-input=false -module-depth=-1'
        when :graph
          '-draw-cycles'
        else
          ''
        end
      end

      "#{@@terraform_bin} #{cmd}#{" #{options}" unless options.empty?} #{@stack.data_dir}"
    end
  end
end
