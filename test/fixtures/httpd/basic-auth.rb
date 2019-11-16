use Rack::Auth::Basic do |username, password|
  [username, password] == %w(admin secret)
end

get "/user/passwd" do
  "ok"
end
