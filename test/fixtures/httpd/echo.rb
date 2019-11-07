helpers do
  def debug_params
    params.map { |k, v| "#{k}: #{v}" }.sort.join("\n")
  end

  def interesting_header(name)
    return true if name == "CONTENT_TYPE"
    return true if name =~ /X_/
    false
  end
  
  def debug_headers
    headers = request.each_header.select { |header, _| interesting_header(header) }
    return if headers.empty?
    headers.map { |k, v| "#{k}: #{v}" }.sort.join("\n")
  end

  def debug_body
    verb = request.request_method
    return unless verb == "POST" || verb == "PUT"

    request.body.rewind
    request.body.read
  end
  
  def debug
    [
      request.request_method,
      debug_params,
      debug_headers,
      debug_body
    ].compact.map { |s| "#{s}\n" }.join("")
  end
end
 
get "/"     do 
  debug
   end
    
head "/"    do
  debug
   end
    
post "/"    do
  debug
   end
    
put "/"     do
  debug
   end
    
delete "/"  do
  debug
   end
