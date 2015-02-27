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

    def deployer
      fetch(:deployer)
    end

    def stage
      fetch(:stage, 'production')
    end

    def revision
      `git rev-parse #{branch}`.chomp
    end

    def deploy_target
      [
        slack_app_name,
        branch
      ].join('/') + " (#{revision[0..5]})"
    end

    def self.extended(configuration)
      configuration.load do
        # Add the default hooks by default.
        set :deployer do
          ENV['USER'] || ENV['GIT_AUTHOR_NAME'] || `git config user.name`.chomp
        end

        namespace :slack do
          desc "Notify Slack that the deploy has started."
          task :starting do
            call_slack_api("#{deployer} is deploying #{deploy_target} to #{stage}")
            set(:start_time, Time.now)
          end

          desc "Notify Slack that the deploy has completed successfully."
          task :finished do
            msg = "#{deployer} deployed #{deploy_target} to #{stage} successfully"

            if start_time = fetch(:start_time, nil)
              msg << " in #{Time.now.to_i - start_time.to_i} seconds."
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
