
require 'resourceful'
require 'redis'
require 'json'
require 'digest/md5'
require 'hitimes'

module Resourceful
  class RedisCacheManager

    attr_reader :db

    def initialize(options)
      @logger = options[:logger]
      @db = Redis.new(options)
    end
    
    def lookup(request)
      response = nil
      total_timer = Hitimes::TimedMetric.now("Total cache lookup")
      fetch_timer = Hitimes::TimedMetric.new("Fetching from redis")

      if metadata = fetch_timer.measure { db.list_range(request.uri.to_s, 0, -1) }
        metadata.detect { |meta|
          json = Marshal.load(meta)
          if valid_for?(request, json[:vary_header_values])
            key = json[:key]
            text = fetch_timer.measure { db.get(key) }
            response = Marshal.load(text)
            total_timer.stop
            @logger.debug("    [Redis] cache read: %0.4fs (%0.1f%%) fetching, %0.4f total" %
                          [fetch_timer.sum, fetch_timer.sum / total_timer.sum * 100, total_timer.sum ])
            true
          else
            @logger.debug("[Redis] cache miss")
          end

        }
      end


      response
    end

    def store(request, response)
      @logger.info("Storing in cache")
      key = Digest::MD5.hexdigest(request.uri.to_s)

      response.header['Cache-Control'].match(/max-age=(\d+)/) if response.header['Cache-Control']
      expires = $1
      db.set(key, Marshal.dump(response), expires)

      values = vary_header_values(request, response)
      values = {:vary_header_values => values, :key => key}
      text = Marshal.dump(values)
      db.push_tail(request.uri.to_s, text)
    end

    def invalidate(url)
      db.delete(url)
    end

    protected

    def vary_header_values(request, response)
      values = {}
      response.header['Vary'].each do |name|
        values[name] = request.header[name]
      end if response.header['Vary']
      values
    end

    def valid_for?(request, vary_header_values)
      vary_header_values.all? do |name, value|
        request.header[name] == value
      end
    end

  end
end
