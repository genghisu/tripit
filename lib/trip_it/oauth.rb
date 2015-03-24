module TripIt
  class OAuth < Base
    attr_reader :consumer, :access_token
    exceptions :bad_request_exception, :unauthorized_exception, :not_found_exception, :server_error, :forbidden_exception, :service_unavailable_error
    
    def initialize(ctoken, csecret, site)
      @consumer = ::OAuth::Consumer.new(ctoken, csecret, :site => site)
    end
    
    def set_callback_url(url)
      @request_token = nil
      request_token(:oauth_callback => url)
    end
    
    def request_token(options={})
      @request_token ||= consumer.get_request_token(options)
    end
    
    def authorize_from_request(rtoken, rsecret, verifier)
      request_token = ::OAuth::RequestToken.new(consumer, rtoken, rsecret)
      access = request_token.get_access_token(:oauth_verifier => verifier)
      @access_token = ::OAuth::AccessToken.new(consumer, access.token, access.secret)
    end
    
    def authorize_from_access(atoken, asecret)
      @access_token = ::OAuth::AccessToken.new(consumer, atoken, asecret)
    end
    
    def get(resource, params={})
      params.merge!(:format => "json")
      params_string = params.collect{|k, v| "#{k}/#{v}"}.join('/')
      request = access_token.get("/v1/get#{resource}/#{URI.escape(params_string)}")
      returnResponse(request)
    end
    
    def list(resource, params={})
      params.merge!(:format => "json")
      params_string = params.collect{|k, v| "#{k}/#{v}"}.join('/')
      request = access_token.get("/v1/list#{resource}/#{URI.escape(params_string)}")
      returnResponse(request)
    end
    
    # Only takes XML
    def create(param)
      request = access_token.post("/v1/create", "xml=<Request>#{URI.escape(param)}</Request>", {'Content-Type' => 'application/x-www-form-urlencoded'})
      returnResponse(request, "xml")
    end
    
    # Only takes XML
    def replace(resource, param)
      request = access_token.post("/v1/replace#{resource}", "xml=<Request>#{URI.escape(param)}</Request>", {'Content-Type' => 'application/x-www-form-urlencoded'})
      returnResponse(request, "xml")
    end        
    
    def delete(resource, params={})
      params.merge!(:format => "json")
      params_string = params.collect{|k, v| "#{k}/#{v}"}.join('/')
      request = access_token.get("/v1/delete#{resource}/#{URI.escape(params_string)}")
      returnResponse(request)
    end
    
    def subscribe(resource)
      request = access_token.get("/v1/subscribe/type#{resource}")
      returnResponse(request)
    end
    
    def unsubscribe
      request = access_token.get("/v1/unsubscribe")
      returnResponse(request)
    end
    
    def returnResponse(request, format = "")
      case request
      when Net::HTTPOK
        if format == "xml"
          return request.body
        else
          return JSON.parse(request.body) 
        end
      when Net::HTTPBadRequest
        raise BadRequestException, request.body
      when Net::HTTPUnauthorized
        raise UnauthorizedException, request.body
      when Net::HTTPNotFound
        raise NotFoundException, request.body
      when Net::HTTPInternalServerError
        raise ServerError, request.body
      when Net::HTTPForbidden
        raise ForbiddenException, request.body
      when Net::HTTPServiceUnavailable
        raise ServiceUnavailableError, request.body
      end
    end
  end
end
