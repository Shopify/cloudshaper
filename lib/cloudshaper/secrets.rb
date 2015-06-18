require 'json'
require 'open3'

module Cloudshaper
  SECRETS_FILES = '/usr/local/cloudshaper/secrets.ejson,config/secrets.ejson'
  secrets_files = (ENV['SECRETS_FILES'] || SECRETS_FILES).split(',')

  SECRETS = secrets_files.inject({}) do |secrets, secrets_file|
    if File.exist?(secrets_file)
      if secrets_file.end_with?('.ejson')
        secrets_blob = `ejson decrypt #{secrets_file}`
      elsif secrets_file.end_with('.json')
        secrets_blob = File.read(secrets_file)
      else
        fail "I don't understand how to get secrets from #{secrets_file}"
      end
      secrets.merge!(JSON.parse(secrets_blob)['cloudshaper'] || {})
    end
    secrets
  end.freeze
end
