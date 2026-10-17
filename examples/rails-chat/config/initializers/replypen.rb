# frozen_string_literal: true

ReplyPen::Embassy.configure do |config|
  config.chat_secret = ENV.fetch("REPLYPEN_CHAT_SECRET")
  config.chat_project = ENV.fetch("REPLYPEN_CHAT_PROJECT")
  config.logger = Rails.logger
end
