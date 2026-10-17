# frozen_string_literal: true

class ReplypenChatController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def token
    origin = allowed_origin
    return head :forbidden unless origin
    return head :too_many_requests unless token_mint_allowed?

    response.set_header("Cache-Control", "no-store")
    render json: {
      token: ReplyPen::Embassy.chat_token(**chat_identity(origin: origin)),
      project: ReplyPen::Embassy.config.chat_project,
      # Server-built so the loader contract version stays owned by the gem — a
      # hardcoded `?v=` in JavaScript would silently drift on a gem upgrade.
      loaderUrl: loader_url
    }
  end

  private

  def loader_url
    chat = ReplyPen::Embassy::Chat
    "#{ReplyPen::Embassy.config.chat_base_url}#{chat::LOADER_PATH}?v=#{chat::LOADER_CONTRACT}"
  end

  def chat_identity(origin:)
    {
      external_id: current_user.id.to_s,
      kind: "app_user",
      tenant: current_tenant&.slug,
      origin: origin
    }
  end

  def allowed_origin
    origin = ReplyPen::Embassy::Chat.normalize_origin(request.headers["Origin"])
    origin if chat_origins.include?(origin)
  rescue ReplyPen::Embassy::Error
    nil
  end

  def chat_origins
    @chat_origins ||= ENV.fetch("REPLYPEN_CHAT_ORIGINS").split(",").map { |origin|
      ReplyPen::Embassy::Chat.normalize_origin(origin.strip)
    }.uniq.freeze
  end

  # Use a shared Rails cache in multi-process deployments so this limit is fleet-wide.
  def token_mint_allowed?
    principal = Digest::SHA256.hexdigest(current_user.id.to_s)
    count = Rails.cache.increment("replypen:chat-token:#{principal}", 1, expires_in: 1.minute)
    count && count <= 12
  end
end
