if ENV["RAILS_ENV"] == "development"
  worker_processes 4
else
  worker_processes 4
end

timeout 30
listen 3020