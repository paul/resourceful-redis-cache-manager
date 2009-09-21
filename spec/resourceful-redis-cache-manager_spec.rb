require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ResourcefulRedisCacheManager" do
  before do
    @http = Resourceful::HttpAccessor.new
    logger = Resourceful::StdOutLogger.new
    @http.logger = logger
    @http.cache_manager = Resourceful::RedisCacheManager.new(:host => 'localhost', :port => '6379', :logger => logger)
    @http.cache_manager.db.flush_db

    @resource = @http.resource("http://rubyforge.org/")
  end


  it 'should do something' do
    @resource.get
    @resource.get
  end
end
