module CodeProcessor
	def decode decode_string,decode_hash
		decode_result = {}

		return if check_string decode_string		# 检查字符串长度是否正确

		decode_hash.each do |name,info_hash|
			next if name == :resp_code						#收到数据不含有，响应码

			string_length = info_hash[:length]		
			if name == :card											#银行卡号不是固定的长度，需要用账户的长度减去电话号码的长度，计算得到
				string_length = decode_result[:account_len].to_i-decode_hash[:phone][:length]
			end

			#取得需要解码的string的长度
			string_temp = decode_string.slice!(0,string_length)
			if info_hash[:type] == :ascii_convert
				string_temp = ascii_to_string string_temp
			end

			#得到数据的名字，对应内容
			decode_result[name] = string_temp
		end

		decode_result[:trade_time].prepend decode_result[:trade_date]
		decode_result
	end


	def encode data_hash,encode_hash
		encode_string = ""

		data_hash[:trade_time] = data_hash[:trade_time].slice!(-6..-1)
		encode_hash.each do |name,info_hash|
			next if (name == :msg_len || (!data_hash.has_key? name))
			
			string_temp = data_hash[name]
			if info_hash[:type] == :ascii_convert
				string_temp = string_to_ascii string_temp
			end
			encode_string << string_temp
		end

		#add msg_length
		msg_length = encode_string.size.to_s(16).rjust(4,"0").upcase
		encode_string.insert(0,msg_length)

		encode_string
	end

	private

	def check_string decode_string
		decode_string.size == decode_string[0,4].hex.to_i-4
	end

	def ascii_to_string ascii_code
		ascii_array = ascii_code.scan(/../)
		ascii_array = ascii_array.map do |variable|
			variable.hex
		end
		string_array = ascii_array.pack("c*")
		string_array
	end

	def string_to_ascii data_string
		data_string = data_string.unpack("H*").join.upcase
		data_string
	end
end




