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

  def connection_completed
    @connected = true
  end

  def connected?
    @connected || false
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
    @connection = -> { FakeRedisClient.connect }
  end

  around(:each) do |example|
    EM.run { example.run }
  end

  def redis
    @redis ||= @connection[]
  end

  def finish
    EM.stop
  end

  # The example code block is executed within the :onclose lambda
  def test_with_redis
    redis.onclose = -> do
      yield
      finish
    end
    # We call this explicitly so that the :onclose lambda is invoked
    redis.close_connection
  end
  
  describe "when connecting" do
    it "should have a default host" do
      test_with_redis do
        redis.instance_variable_get(:@host).should == "localhost"
      end
    end

    it "should have a default port" do
      test_with_redis do
        redis.instance_variable_get(:@port).should == 6379
      end
    end

    it "should be connected to the redis server" do
      test_with_redis do
        redis.connected?.should == true
      end
    end
  end

end
