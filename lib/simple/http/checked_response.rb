module Simple::HTTP::CheckedResponse
  SELF = self

  def get!(url, headers = {}, into: nil)
    response = perform_request!(:GET, url, nil, headers)
    response.checked_content(into: into)
  end

  def options!(url, headers = {}, into: nil)
    response = perform_request!(:OPTIONS, url, nil, headers)
    response.checked_content(into: into)
  end

  def post!(url, body = nil, headers = {}, into: nil)
    response = perform_request!(:POST, url, body, headers)
    response.checked_content(into: into)
  end

  def put!(url, body = nil, headers = {}, into: nil)
    response = perform_request!(:PUT, url, body, headers)
    response.checked_content(into: into)
  end

  def delete!(url, headers = {}, into: nil)
    response = perform_request!(:DELETE, url, nil, headers)
    response.checked_content(into: into)
  end
end
