require 'hknife/version'
require 'net/http'
require 'uri'
require 'pp'
require 'json'

module Hknife

  class Request
    @@objects = {}

    def initialize
      @headers = {}
      @response = nil
      @requestor = nil
      @request = nil
      @http_client = nil
    end

    def get(uri)
      uriObj = URI.parse(uri)
      @http_client = Net::HTTP.new(uriObj.host, uriObj.port)
      @http_client.use_ssl = uriObj.scheme == 'https'
      @request = Net::HTTP::Get.new(uriObj.path)
      @requestor = lambda do |request| 
        res = @http_client.request(request) 
        case res['Content-Type']
        when /application\/json/ then
          res.body = JSON.parse(res.body)
        end
        res
      end
      self
    end

    def delete(uri)
      uriObj = URI.parse(uri)
      @http_client = Net::HTTP.new(uriObj.host, uriObj.port)
      @http_client.use_ssl = uriObj.scheme == 'https'
      @request = Net::HTTP::Delete.new(uriObj.path)
      @requestor = lambda do |request| 
        res = @http_client.request(request) 
        case res['Content-Type']
        when /application\/json/ then
          res.body = JSON.parse(res.body)
        end
        res
      end
      self
    end    

    def put(uri, data)
      uriObj = URI.parse(uri)
      @http_client = Net::HTTP.new(uriObj.host, uriObj.port)
      @http_client.use_ssl = uriObj.scheme == 'https'
      @request = Net::HTTP::Put.new(uriObj.path)
      @requestor = lambda do |request| 
        res = @http_client.request(request) 
        case res['Content-Type']
        when /application\/json/ then
          res.body = JSON.parse(res.body)
        end
        res
      end
      self
    end

    def post_form(uri, data)      
      uriObj = URI.parse(uri)
      @http_client = Net::HTTP.new(uriObj.host, uriObj.port)
      @http_client.use_ssl = uriObj.scheme == 'https'
      @request = Net::HTTP::Post.new(uriObj.path)
      @requestor = lambda do |request| 
        res = @http_client.request(@request, URI.encode_www_form(data))

        case res['Content-Type']
        when /application\/json/ then
          res.body = JSON.parse(res.body)
        end
        res
        end        
      self
    end

    def header(hsh)
      @headers = {} if @headers.nil?
      hsh.each do |key, val|
        @headers[key] = val
      end
      self
    end

    def async(&block)
      @async_thread = Thread.new do
        @response = @requestor.call(@request)
        block.call @response if block_given?
      end
    end

    def wait
      @async_thread.join
    end

    def request
      @request
    end

    def response
      @headers.each_pair {|k, v| @request.add_field(k, v)}
      @response = @requestor.call(@request)
      @response
    end
  end

  class RequestQueue
    def initialize
      @queue = []
    end

    def get(uri)
      req = Request.new()
      req.get(uri)
      @queue << req
      self
    end

    def delete(uri)
      req = Request.new()
      req.delete(uri)
      @queue << req
      self
    end    

    def post_form(uri, data)  
      req = Request.new()
      req.post_form(uri, data)
      @queue << req       
      self
    end

    def put(uri, data)  
      req = Request.new()
      req.put(uri, data)
      @queue << req       
      self
    end    

    def header(hdr)
      @queue.last.header(hdr)
      self
    end

    def async(&block)
      @queue.each do |req|
        req.async(block)
      end
    end

    def send()
      @queue.each do |req|
        req.async
      end

      @queue.each do |req|
        req.wait
      end         
    end

    def request(idx = nil)
      if idx.nil?
        @queue.last.request
      else
        @queue[idx].request        
      end      
    end

    def response(idx = nil)
      if idx.nil?
        @queue.last.response
      else
        @queue[idx].response        
      end
    end

    class << self
      def get(uri)
        obj = RequestQueue.new
        obj.get(uri)

        if block_given?
          yield obj.request, obj.response
        end

        obj
      end

      def delete(uri)
        obj = RequestQueue.new
        obj.delete(uri)

        if block_given?
          yield obj.request, obj.response
        end

        obj
      end      

      def post_form(uri, data)
        obj = RequestQueue.new
        obj.post_form(uri, data)

        if block_given?
          yield obj.request, obj.response
        end

        obj
      end

      def put(uri, data)
        obj = RequestQueue.new
        obj.put(uri, data)

        if block_given?
          yield obj.request, obj.response
        end

        obj
      end      

      def header(hsh)
        obj = RequestQueue.new
        obj.header(hsh)
        obj
      end

      def parallel
        yield
      end   
    end
  end

  module Delegator #:nodoc:
    def self.delegate(*methods)
      methods.each do |method_name|
        define_method(method_name) do |*args, &block|
          return super(*args, &block) if respond_to? method_name
          Delegator.target.send(method_name, *args, &block)
        end
        private method_name
      end
    end

    delegate :get, :post_form, :request, :header, :parallel, :put, :delete

    class << self
      attr_accessor :target
    end

    self.target = RequestQueue
  end  
end

extend Hknife::Delegator