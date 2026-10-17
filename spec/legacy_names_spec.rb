# frozen_string_literal: true

# Installed apps (Gemfile `gem "rootcause-embassy"`, initializers on `RootCause::Embassy`) must keep
# booting unchanged against this gem. CI builds both gemspecs; this pins the in-process surface.
RSpec.describe "legacy rootcause names" do
  it "keeps every legacy require path loadable" do
    %w[rootcause-embassy rootcause/embassy replypen-embassy replypen/embassy].each do |path|
      expect { require path }.not_to raise_error
    end
  end

  it "aliases RootCause to the same module, so singletons and class identity are shared" do
    expect(RootCause).to equal(ReplyPen)
    expect(RootCause::Embassy::Chat).to equal(ReplyPen::Embassy::Chat)
    expect(RootCause::Embassy::TriggerError.new("x")).to be_a(ReplyPen::Embassy::TriggerError)
    expect(defined?(Rootcause)).to be_nil
  end

  it "configures through RootCause::Embassy and mints the replypen audience" do
    RootCause::Embassy.configure do |c|
      c.chat_secret = Wire::CHAT_SECRET
      c.chat_project = Wire::CHAT_PROJECT
      c.logger = Logger.new(File::NULL)
    end

    expect(ReplyPen::Embassy.config).to equal(RootCause::Embassy.config)
    token = RootCause::Embassy.chat_token(external_id: "u1", kind: "acme_admin", origin: Wire::CHAT_ORIGIN)
    _header, claims = Wire.decode_jwt(token)
    expect(claims["aud"]).to eq("replypen:chat:#{Wire::CHAT_PROJECT}")
  end
end
