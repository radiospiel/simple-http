get "/" do
end

get "/status/:status" do
  status params[:status]
  "No content"
end

get "/redirect-to" do
  redirect params[:url]
end

get "/redirection-target" do
  content_type :html
  "I am the redirection target"
end
