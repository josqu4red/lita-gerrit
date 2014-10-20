require "spec_helper"

describe Lita::Handlers::Gerrit, lita_handler: true do

  before do
    Lita.configure do |config|
      config.handlers.gerrit.url = "https://gerrit.example.com"
      config.handlers.gerrit.username = "foo"
      config.handlers.gerrit.password = "bar"
    end
  end

  it { routes("get me gerrit 123, please").to(:change_details) }
  it { doesnt_route("gerrit foo").to(:change_details) }

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
      expect(replies.last).to eq("gerrit: haproxy : migrate beanstalk frontend by John Doe in chef. https://gerrit.example.com/42")
    end

    it "replies that the issue doesn't exist" do
      allow(response).to receive(:code).and_return(404)

      send_command("gerrit 42")

      expect(replies.last).to eq("Change #42 does not exist")
    end

    it "replies with an exception message" do
      allow(response).to receive(:code).and_return(500)

      send_command("gerrit 42")

      expect(replies.last).to match("Error: Failed to fetch https://gerrit.example.com/a/changes/42 (500)")
    end
  end
end
