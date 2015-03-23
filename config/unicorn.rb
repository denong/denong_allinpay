root = "/home/allinpay/denong/denong_allinpay"
working_directory root
pid "#{root}/tmp/pids/unicorn.pid"
stderr_path "#{root}/log/unicorn.log"
stdout_path "#{root}/log/unicorn.log"

listen "/tmp/unicorn.allinpay.sock"
worker_processes 10
timeout 30

# Force the bundler gemfile environment variable to
# # reference the capistrano "current" symlink
# before_exec do |_|
#   ENV["BUNDLE_GEMFILE"] = File.join(root, 'Gemfile')
#   end