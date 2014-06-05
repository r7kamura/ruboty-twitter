require "mem"
require "twitter"

module Ruboty
  module Adapters
    class Twitter < Base
      include Mem

      env :TWITTER_CONSUMER_KEY, "Twitter consumer key (a.k.a. API key)"
      env :TWITTER_CONSUMER_SECRET, "Twitter consumer secret (a.k.a. API secret)"
      env :TWITTER_ACCESS_TOKEN, "Twitter access token"
      env :TWITTER_ACCESS_TOKEN_SECRET, "Twitter access token secret"

      def run
        abortable
        listen
      end

      def say(message)
        case message
        when String
          body = message
        when Hash
          body = message[:body]
          if tweet = message[:original][:tweet]
            options = { in_reply_to_status_id: tweet.id }
          end
        end

        client.update(body, options)
      end

      private

      def listen
        stream.user do |tweet|
          case tweet
          when ::Twitter::Tweet
            robot.receive(
              body: tweet.text,
              from: tweet.user.screen_name,
              tweet: tweet
            )
          end
        end
      end

      def client
        ::Twitter::REST::Client.new do |config|
          config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
          config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
          config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
          config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
        end
      end
      memoize :client

      def stream
        ::Twitter::Streaming::Client.new do |config|
          config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
          config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
          config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
          config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
        end
      end
      memoize :stream

      def abortable
        Thread.abort_on_exception = true
      end
    end
  end
end
