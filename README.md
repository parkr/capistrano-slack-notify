# Capistrano::SlackNotify

Capistrano 2 deploy notifier for Slack.

![Sample Slack output.](https://raw.githubusercontent.com/parkr/capistrano-slack-notify/master/Screen%20Shot%202015-02-06%20at%205.52.10%20PM.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-slack-notify'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-slack-notify

## Usage

`capistrano-slack-notify` defines two tasks:

Add the following to your `Capfile`:

```ruby
require 'capistrano-slack-notify'

set :slack_webhook_url,   "https://hooks.slack.com/services/XXX/XXX/XXX"

before 'deploy', 'slack:starting'
after  'deploy', 'slack:finished'
```

That's it! It'll send 2 messages to `#general` as the `capistrano` user when you deploy.
You can optionally set some other parameters:

```ruby
set :slack_room,     '#my_channel' # defaults to #platform
set :slack_username, 'my-company-bot' # defaults to 'capistrano'
set :slack_emoji,    ':ghost:' # defaults to :rocket:
set :deployer,       ENV['USER'].capitalize # defaults to ENV['USER']
set :slack_app_name, 'example-app' # defaults to :application
```

## Contributing

1. Fork it ( https://github.com/parkr/capistrano-slack-notify/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
