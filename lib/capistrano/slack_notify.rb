require 'capistrano'
require 'json'
require 'net/http'
require 'open3'

module Capistrano
  module SlackNotify
    HEX_COLORS = {
      :grey  => '#CCCCCC',
      :red   => '#BB0000',
      :green => '#7CD197',
      :blue  => '#103FFB'
    }

    def post_to_channel(color, message, extra_attachment=nil)
      if use_color?
        call_slack_api(attachment_payload(color, message, extra_attachment))
      else
        call_slack_api(regular_payload(message, extra_attachment))
      end
    end

    def call_slack_api(payload)
      uri = URI.parse(slack_webhook_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(:payload => payload)
      http.request(request)
    rescue SocketError => e
       puts "#{e.message} or slack may be down"
    end

    def regular_payload(announcement, extra_attachment=nil)
      payload = {
        'channel'    => slack_channel,
        'username'   => slack_username,
        'text'       => announcement,
        'icon_emoji' => slack_emoji,
        'mrkdwn'     => true
      }
      if extra_attachment
        add_payload_attachment(payload, extra_attachment)
      end
      payload.to_json
    end

    def attachment_payload(color, announcement, extra_attachment=nil)
      payload = {
        'channel'     => slack_channel,
        'username'    => slack_username,
        'icon_emoji'  => slack_emoji
      }
      add_payload_attachment(payload, announcement, color)
      if extra_attachment
        add_payload_attachment(payload, extra_attachment)
      end
      payload.to_json
    end

    # Add an attachment to the payload
    #
    # :param payload: the payload to fill
    # :param text: the attachment text
    # :param color: the optionnal color in HEX_COLORS hash
    def add_payload_attachment(payload, text, color=nil)
      attachment = {
        'fallback'  => text,
        'text'      => text,
        'mrkdwn_in' => %w{text}
      }
      if color
        attachment["color"] = HEX_COLORS[color]
      end
      if ! payload.key?("attachments")
        payload["attachments"] = [attachment]
      else
        payload["attachments"] << attachment
      end
    end

    def get_changelog()
      begin
        last_revision = IO.readlines("#{current_path}/revisions.log")[-1]
        last_revision = /Branch .* \(at ([0-9a-z]+).*/.match(last_revision)[0]

        result = '```'
        Open3.popen3('git', '--no-pager', 'log', '--no-merges', '--no-color', '--pretty=- %s', '%s..%s' % [last_revision, rev]) do |stdin, stdout, stderr, wait_thr|
          result = stdout.read
        end
        return result
      rescue
        return nil
      end
    end

    def use_color?
      fetch(:slack_color, true)
    end

    def slack_webhook_url
      fetch(:slack_webhook_url)
    end

    def slack_channel
      fetch(:slack_room, '#platform')
    end

    def slack_username
      fetch(:slack_username, 'capistrano')
    end

    def slack_emoji
      fetch(:slack_emoji, ':rocket:')
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

    def destination
      fetch(:slack_destination, stage)
    end

    def repository
      fetch(:repository, 'origin')
    end

    def rev
      @rev ||= `git ls-remote #{repository} #{branch}`.split(" ").first
    end

    def deploy_target
      [slack_app_name, branch].join('/') + (rev ? " (#{rev[0..5]})" : "")
    end

    def slack_add_changelog
      fetch(:slack_add_changelog, false)
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

            on_rollback do
              post_to_channel(:red, "#{deployer} *failed* to deploy #{deploy_target} to #{destination}")
            end

            post_to_channel(:grey, "#{deployer} is deploying #{deploy_target} to #{destination}")
            set(:start_time, Time.now)
          end

          desc "Notify Slack that the rollback has completed."
          task :rolled_back do
            post_to_channel(:green, "#{deployer} has rolled back #{deploy_target}")
          end

          desc "Notify Slack that the deploy has completed successfully."
          task :finished do
            msg = "#{deployer} deployed #{deploy_target} to #{destination} *successfully*"

            if start_time = fetch(:start_time, nil)
              msg << " in #{Time.now.to_i - start_time.to_i} seconds."
            else
              msg << "."
            end

            if slack_add_changelog
              changelog = get_changelog
            else
              changelog = nil
            end
            post_to_channel(:green, msg, changelog)
          end

          desc "Notify Slack that the deploy failed."
          task :failed do
            post_to_channel(:red, "#{deployer} *failed* to deploy #{deploy_target} to #{destination}")
          end
        end # end namespace :slack
      end
    end # end self.extended

  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::SlackNotify)
end
