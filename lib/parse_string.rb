module CodeProcessor
	def decode decode_string,decode_hash
		decode_result = {}

		return unless check_string decode_string		# 检查字符串长度是否正确

		decode_hash.each do |name,info_hash|
			next if name == :resp_code						#收到数据不含有，响应码

			string_length = info_hash[:length]		
			if name == :card											#银行卡号不是固定的长度，需要用账户的长度减去电话号码的长度，计算得到
				string_length = decode_result[:account_len].to_i-decode_hash[:phone][:length]
			end

			#取得需要解码的string的长度
			string_temp = decode_string.slice!(0,string_length)
			return unless string_temp
			case info_hash[:type]
			when :ascii_convert then
				string_temp = ascii_to_string string_temp
			when :bcd_byte then
				string_temp = string_temp.to_i*2	
			when :bcd_even then
				string_temp = string_temp[0,string_temp.size-1] if string_temp[-1] == "A"
			end
			if name == :phone
				string_temp = string_temp[1..string_temp.size]
			end
			#得到数据的名字，对应内容
			decode_result[name] = string_temp
		end

		decode_result[:trade_time].prepend decode_result[:trade_date]
		decode_result[:trade_time].prepend DateTime.now.strftime("%Y")
		decode_result[:price] = decode_result[:price].to_f/100
		decode_result
	end


	def encode data_hash,encode_hash
		encode_string = ""

		data_hash[:trade_time] = data_hash[:trade_time].slice!(-6..-1)
		data_hash[:bit_map][-7] = "A"
		encode_hash.each do |name,info_hash|
			next if (name == :msg_len || (!data_hash.has_key? name))
			
			string_temp = data_hash[name]
			case info_hash[:type]
			when :ascii_convert then
				string_temp = string_to_ascii string_temp
			when :bcd_byte then
				string_temp = (string_temp.to_i/2).to_s	
			when :bcd_even then
				string_temp = string_temp.concat("A") if string_temp.size%2 == 1
			end
			if name == :phone
				string_temp = "1#{string_temp}"
			elsif name == :price
				string_temp = (string_temp*100).to_i.to_s.rjust(12,"0")
			end
			encode_string << string_temp
		end

		#add msg_length
		msg_length = (encode_string.size/2).to_s(16).rjust(4,"0").upcase
		encode_string.insert(0,msg_length)
		data_hash[:msg_len] = msg_length
		puts "encode data is #{encode_string}, its size is #{encode_string.size}\n"
		ascii_to_string encode_string
	end

	private

	def check_string decode_string
		return_bool = false
		return_bool = true if (decode_string.size.to_i == (decode_string[0,4].hex.to_i)*2+4)
		return_bool
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

