require 'erb'
require 'ostruct'

module Cloudshaper

  TEMPLATE_SOURCE = 'git@github.com:Shopify/terraform-modules//templates?ref=template_test'
  CACHE_DIR = '.cloudshaper_cache'

  class Template < OpenStruct
    def render(template)
      template_data = File.read(refresh(template))
      rendered = ERB.new(template_data).result(binding)
    end

    def self.cache
     ENV['CACHE_DIR'] || CACHE_DIR
    end

    def self.source
      full_uri = (ENV['TEMPLATE_SOURCE'] || TEMPLATE_SOURCE)
      folder = full_uri.match(/\/\/(.*)\?+/).captures.first
      uri = full_uri.match(/(.*)\/\/+|\?+/).captures.first
      ref_check = full_uri.match(/\?ref=(.*)/)
      ref = (ref_check.captures.first if ref_check) || 'master'
      {uri: uri, folder: folder, ref: ref}
    end
  private

    # Fetch template from template source
    def refresh(template)
      git(clone(Template.source[:uri])) unless Dir.exist? Template.cache
      git(fetch)
      git(checkout(Template.source[:ref]))
      template_path = File.join(Template.cache, Template.source[:folder], "#{template}.tf.erb")
      fail "#{template} doesn't exist at #{template_path}" unless File.exist?(template_path)
      template_path
    end

    def checkout(ref)
      "-C #{Template.cache} checkout origin/#{ref}"
    end

    def clone(uri)
      "clone #{uri} #{Template.cache}"
    end

    def fetch
      "-C #{Template.cache} fetch "
    end

    def git(command)
      puts command
      Process.waitpid(spawn("git #{command}"))
      puts $?.exitstatus
      fail 'Command failed' unless $?.exitstatus == 0
    end
  end
end
