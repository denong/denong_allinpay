# require 'rubygems' 
# require 'eventmachine' 
# module Server 
# 	def receive_data(data)
# 		puts data 
# 		send_data("helo\n") 
# 	end
# end
# EM.run { EM.start_server 'localhost', 8081, Server }

require 'rubygems'
require "daemons"

Daemons.run('denong_allinpay.rb')