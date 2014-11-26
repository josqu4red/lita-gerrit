require "spec_helper"
require "stringio"

describe Lita::Handlers::Gerrit, lita_handler: true do

  before do
    Lita.configure do |config|
      config.handlers.gerrit.url = "https://gerrit.example.com"
      config.handlers.gerrit.username = "foo"
      config.handlers.gerrit.password = "bar"
    end
  end

  it { is_expected.to route("get me gerrit 123, please").to(:change_details) }
  it { is_expected.not_to route("gerrit foo").to(:change_details) }

  describe "#change_details" do
    let(:response) { double("HTTParty::Response") }
    let(:body) { File.read("spec/fixtures/change_details.json") }

    before do
      allow(HTTParty).to receive(:get).and_return(response)
    end

    it "replies with the title and URL for the issue" do
      allow(response).to receive(:code).and_return(200)
      allow(response).to receive(:body).and_return(body)

      send_command("gerrit 42")
      expect(replies.last).to eq('[gerrit] [chef] "haproxy : migrate beanstalk frontend" by John Doe. https://gerrit.example.com/42')
    end

    it "replies that the issue doesn't exist" do
      allow(response).to receive(:code).and_return(404)

      send_command("gerrit 42")

      expect(replies.last).to eq("[gerrit] Change #42 does not exist")
    end

    it "replies with an exception message" do
      allow(response).to receive(:code).and_return(500)

      send_command("gerrit 42")

      expect(replies.last).to match("[gerrit] Error: Failed to fetch https://gerrit.example.com/a/changes/42 (500)")
    end
  end

  it { is_expected.to route_http(:post, "/gerrit/hooks").to(:hook) }

  describe "#hook" do
    let(:request) do
      request = double("Rack::Request")
      allow(request).to receive(:params).and_return(params)
      request
    end

    let(:response) { Rack::Response.new }

    let(:params) { double("Hash") }
  end

  it { is_expected.to route_http(:post, "/gerrit/build/myroom").to(:build_notification) }
  it { is_expected.not_to route_http(:post, "/gerrit/build/").to(:build_notification) }

  describe "#build_notification" do
    let(:request) { double("Rack::Request") }
    let(:response) { Rack::Response.new }
    let(:env) { {"router.params" => { :room => "myroom" }} }
    let(:body) { File.read("spec/fixtures/build_notification.json") }

    context "build finalized" do
      before do
        allow(request).to receive(:env).and_return(env)
        allow(request).to receive(:body).and_return(StringIO.new(body))
      end

      it "notifies the applicable room" do
        expect(robot).to receive(:send_message) do |target, message|
          expect(target.room).to eq("myroom")
          expect(message).to eq('jenkins: Build "haproxy: enable HTTP compression on kibana frontend" by Hervé in sysadmin/chef OK')
        end
        subject.build_notification(request, response)
      end
    end
  end
end
