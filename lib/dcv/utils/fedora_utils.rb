module Dcv::Utils::FedoraUtils

  def self.risearch(user_search_params)

    # Required
    if ! user_search_params.include?(:query)
      raise 'Error: No query specified for risearch.'
    end

    risearch_params = {}
    risearch_params['type'] = 'tuples'
    risearch_params['lang'] = 'itql'
    risearch_params['format'] = 'json'
    risearch_params['limit'] = '' # empty string means unlimited results
    risearch_params['stream'] = 'on'
    risearch_params['query'] = user_search_params[:query]

    uri = URI.parse(ActiveFedora.config.credentials[:url] + '/risearch')
    uri.query = URI.encode_www_form(risearch_params)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # if uri.scheme == 'https' && uri.host == 'localhost'

    risearch_request = Net::HTTP::Get.new(uri.request_uri)
    risearch_request.basic_auth(ActiveFedora.config.credentials[:user], ActiveFedora.config.credentials[:password])
    risearch_response = http.request(risearch_request)

    return JSON(risearch_response.body)

  end
  def self.to_uri(subject)
    if subject.is_a? ActiveFedora::Base
      return "info:fedora/#{subject.pid}"
    end
    if subject.is_a? ActiveFedora::Datastream
      return "info:fedora/#{subject.pid}/#{subject.dsid}"
    end
    return subject.to_s 
  end
  def self.add_relationship(subject,predicate,object,is_literal=false)
    params = {}
    params[:subject] = to_uri(subject)
    params[:predicate] = to_uri(predicate)
    params[:object] = object.to_s
    params[:isLiteral] = is_literal.to_s.downcase
    uri = URI.parse(
      ActiveFedora.config.credentials[:url] +
      "/objects/#{subject.pid}/relationships/new")
    uri.query = URI.encode_www_form(params)
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.use_ssl = true if uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # if uri.scheme == 'https' && uri.host == 'localhost'

      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(ActiveFedora.config.credentials[:user], ActiveFedora.config.credentials[:password])
      return http.request(request).status
    end
  end
  def self.get_top_level_all_content_fedora_object
    begin
      top_level_all_content_fedora_object = BagAggregator.find(HYACINTH_CONFIG['top_level_all_content_fedora_object_id'])
      #puts 'Found top_level_all_content_fedora_object: ' + top_level_all_content_fedora_object.inspect
    rescue ActiveFedora::ObjectNotFoundError
      puts 'Could not find top_level_all_content_fedora_object.  Creating one now.'
      # Create top_level_all_content_fedora_object if it wasn't found
      top_level_all_content_fedora_object = BagAggregator.new(:pid => HYACINTH_CONFIG['top_level_all_content_fedora_object_id'])
      top_level_all_content_fedora_object.save
    end

    return top_level_all_content_fedora_object
  end

  def self.next_pid(namespace="ldpd")
    ActiveFedora::Base.fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)
    repo = ActiveFedora::Base.fedora_connection[0].connection
    pid = nil
    begin
      pid = repo.mint(:namespace=>namespace)
    end while exists? pid
    pid
  end

  def self.exists?(pid)
    begin
      return ActiveFedora::Base.exists? pid
    rescue => e
      return false
    end
  end

end
