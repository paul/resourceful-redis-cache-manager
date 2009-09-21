require 'rubygems'

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../../resourceful/lib/"))
require 'resourceful'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'resourceful-redis-cache-manager'

@http = Resourceful::HttpAccessor.new
logger = Resourceful::StdOutLogger.new
@http.logger = logger
@http.cache_manager = Resourceful::RedisCacheManager.new(:host => 'localhost', :port => '6379', :logger => logger)
@http.cache_manager.db.flush_db

@resource = @http.resource("http://rubyforge.org/")


@resource.get

  100.times do
    @resource.get
  end


