require 'capistrano'
require 'json'
require 'net/http'

module Capistrano
  module SlackNotify
    def call_slack_api(message)
      uri = URI.parse(slack_webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(:payload => payload(message))
      http.request(request)
    rescue SocketError => e
       puts "#{e.message} or slack may be down"
    end

    def slack_defaults
    end

    def payload(announcement)
      {
        'channel' =>    fetch(:slack_room, '#platform'),
        'username' =>   fetch(:slack_username, 'capistrano'),
        'text' =>       announcement,
        'icon_emoji' => fetch(:slack_emoji, ':rocket:')
      }.to_json
    end

    def slack_webhook_url
      fetch(:slack_webhook_url)
    end

    def slack_app_name
      fetch(:slack_app_name, fetch(:application))
    end

    def self.extended(configuration)
      configuration.load do
        # Add the default hooks by default.
        if fetch(:slack_deploy_defaults, true)
          before 'deploy', 'slack:starting'
          after  'deploy', 'slack:finished'
        end

        set :deployer do
          ENV['USER'] || ENV['GIT_AUTHOR_NAME'] || `git config user.name`.chomp
        end

        namespace :slack do
          desc "Notify Slack that the deploy has started."
          task :starting do
            msg = if branch = fetch(:branch, nil)
              "#{fetch(:deployer)} is deploying #{slack_app_name}/#{branch} to #{fetch(:stage, 'production')}"
            else
              "#{fetch(:deployer)} is deploying #{slack_app_name} to #{fetch(:stage, 'production')}"
            end
            call_slack_api(msg)
            set(:start_time, Time.now)
          end

          desc "Notify Slack that the deploy has completed successfully."
          task :finished do
            msg = "#{fetch(:deployer)} deployed to #{slack_app_name} successfully"
            if start_time = fetch(:start_time, nil)
              elapsed = Time.now.to_i - start_time.to_i
              msg << " in #{elapsed} seconds."
            else
              msg << "."
            end
            call_slack_api(msg)
          end
        end # end namespace :slack
      end
    end # end self.extended

  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::SlackNotify)
end
