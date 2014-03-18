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

  it { routes_http(:post, "/gerrit/hooks").to(:hook) }

  describe "#change_details" do
    let(:response) do
      double("HTTParty::Response")
    end

    before do
      allow(HTTParty).to receive(:get).and_return(response)
    end

    it "replies with the title and URL for the issue" do
      allow(response).to receive(:code).and_return(200)

      allow(response).to receive(:body).and_return(<<-JSON.chomp
)]}'
{
  "kind": "gerritcodereview#change",
  "id": "chef~master~Ib0b61ed3eebb8e22596a8401bf976949d798826a",
  "project": "chef",
  "branch": "master",
  "topic": "beanstalk",
  "change_id": "Ib0b61ed3eebb8e22596a8401bf976949d798826a",
  "subject": "haproxy : migrate beanstalk frontend",
  "status": "MERGED",
  "created": "2014-03-14 12:42:15.320000000",
  "updated": "2014-03-17 10:32:21.311000000",
  "_sortkey": "002bcd180000096b",
  "_number": 42,
  "owner": {
    "name": "John Doe"
  }
}
JSON
      )

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
