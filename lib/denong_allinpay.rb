require "eventmachine"
require "./denong_allinpay/version"
require "./parse_string.rb"
require "nokogiri"
require "rest_client"

module DenongAllinpay
	include CodeProcessor

	def post_init
		puts "-- someone connected to the echo server!"
	end

	def receive_data data
		puts "Received #{data}"
		data_process data
		puts "Result is #{@data_hash}"

		send_data @data_hash
		send_data @data_result 
	end

	def unbind
   puts "-- someone disconnected from the echo server!"
 	end

 	private

 	def data_process decode_string
		decode_hash = {
			msg_len: {length: 4, type: :bcd}, 	#消息长度
			tpdu:	{length:10,	type: :binary},			#TPDU
			msg_head: {length:12,	type: :ascii},	#报文头
			msg_type: {length:4, type: :bcd},			#消息类型
			bit_map: {length:16, type: :ascii},		#位元表
			account_len: {length:2, type: :ascii},	#手机号+银行卡号的长度
			phone: {length:22,	type: :ascii_convert},	#手机号
			card: {length: :account_length,	type: :ascii_convert}, 	#卡号
			trade_id: {length:6,	type: :ascii},	#交易处理码
			price: {length:24,	type: :ascii_convert},	#交易金额
			trade_ind: {length:12,	type: :ascii_convert},	#收单方系统跟踪号，交易流水
			trade_time: {length:12,	type: :ascii_convert},	#收单方所在地时间，交易时间
			trade_date: {length:16,	type: :ascii_convert},	#收单方所在地日期，交易日期
			refer_id: {length:24,	type: :ascii_convert},	#检索参考号，POS中心系统流水号/交易参考号
			resp_code: {length:4, type: :ascii_convert},	#应答码
			pos_ind: {length:16, type: :ascii_convert},	#收单方终端标识码，POS终端号
			shop_ind: {length:30, type: :ascii_convert}	#受卡方标识码，商户号
		}

		@data_hash = decode decode_string,decode_hash

		# response = RestClient.post @dest_addr,@data_hash
		# if response.code = 200
		# 	@data_hash[:resp_code] = "00"
		# else
		# 	@data_hash[:resp_code] = "01"
		# end

		#编码时需要加上应答码两个字节,用于调试
		@data_hash[:resp_code] = "00"

		@data_result = encode @data_hash,decode_hash
	end
end


# Note that this will block current thread.
EventMachine.run {
  config_path = "../config/config.xml"
  doc = Nokogiri::XML(open(config_path))
  ip_addr = doc.search("IPAddr").first.content
  port = doc.search("Port").first.content
  EventMachine.start_server ip_addr, port, DenongAllinpay do |em|
    em.dest_addr = doc.search("DestAddr").first.content
  end
  puts "Listening ....."
}