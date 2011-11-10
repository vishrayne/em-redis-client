require 'rspec'

require'eventmachine'

class FakeRedisClient < EM::Connection
  attr_writer :onopen, :onclose, :onmessage

  def self.connect host = "localhost", port = 6379
    EM.connect host, port, self, host, port
  end

  def initialize(host, port)
    @host = host
    @port = port
  end

  def post_init
    @onopen.call if @onopen
  end

  def unbind
    @onclose.call if @onclose
  end
end

describe FakeRedisClient, "an evented redis client" do
  let(:host) { "localhost" }
  let(:port) { 6379 }
  
  before(:each) do
    @redis = -> { FakeRedisClient.connect }
  end

  around(:each) do |example|
    EM.run do
      example.run
      redis.close_connection
    end
  end

  def redis
    @redis[]
  end

  # explicitly stop the event loop
  def finish
    EM.stop
  end
  
  describe "when connecting" do
    it "the default host is localhost" do
      redis.onclose = -> do
        redis.instance_variable_get(:@host).should == "localhost"
        finish
      end
    end

    it "the default port is 6379" do
      redis.onclose = -> do
        redis.instance_variable_get(:@port).should == 6379
        finish
      end
    end
  end
end
