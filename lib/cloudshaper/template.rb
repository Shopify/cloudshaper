require 'erb'

module Cloudshaper

  #TEMPLATE_SOURCE = 'git@github.com:Shopify/terraform-modules//templates?ref=template_test'
  TEMPLATE_SOURCE = 'file:///home/dale.hamel/workspace/shopify/terraform-modules/templates'
  CACHE_DIR = '.cloudshaper_cache'

  class Template
    def self.render(config, template)
      if source[:protocol] == 'git@github.com'
        template_dir = refresh(template)
      elsif source[:protocol] == 'file'
        template_dir = source[:uri]
      else
        fail "#{source[:protocol]} does not use a recognized protocol"
      end

      template_file = File.join(template_dir, "#{template}.tf.erb")
      fail "#{template_file} doesn't exist" unless File.exist? template_file

      template_data = File.read(template_file)
      ERB.new(template_data).result(config.get_binding)
    end

    def self.cache
     ENV['CACHE_DIR'] || CACHE_DIR
    end

    def self.source
      full_uri = (ENV['TEMPLATE_SOURCE'] || TEMPLATE_SOURCE)
      protocol = full_uri.match(/^(.*):/).captures.first
      if protocol == 'file'
        uri = full_uri.gsub('file://','')
      else
        uri = full_uri.match(/^(.*)\/\/\w+|\w\?+/).captures.first
      end
      folder_check = full_uri.match(/\w\/\/(.*)\w\?+/)
      ref_check = full_uri.match(/\w\?ref=(.*)\/*/)
      ref = (ref_check.captures.first if ref_check) || 'master'
      folder = (folder_check.captures.first if folder_check) || ''
      {protocol: protocol, uri: uri, folder: folder, ref: ref}
    end
  private

    # Fetch template from template source
    def self.refresh
      git(clone(source[:uri])) unless Dir.exist? cache
      git(fetch)
      git(checkout(source[:ref]))
      template_dir = File.join(cache, source[:folder])
      template_dir
    end

    def self.checkout(ref)
      "-C #{cache} checkout origin/#{ref}"
    end

    def self.clone(uri)
      "clone #{uri} #{cache}"
    end

    def self.fetch
      "-C #{cache} fetch "
    end

    def self.git(command)
      puts command
      Process.waitpid(spawn("git #{command}"))
      puts $?.exitstatus
      fail 'Command failed' unless $?.exitstatus == 0
    end
  end
end
