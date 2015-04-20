require "./denong_allinpay/version"
require "./parse_string.rb"
require "nokogiri"
require "rest_client"
require 'thin'
require "socket"

class Allinpay
  include CodeProcessor
  def process data
    puts "Received #{data}\n"
    @data_result = data_process data
    puts "encode hash is #{@data_hash}\n"
    puts "encode data is #{@data_result}, its class is #{@data_result.class}\n"
    @data_result
  end
  
  private
  def data_process decode_string
    decode_hash = {
      msg_len: {length: 4, type: :bcd},   #消息长度
      tpdu: {length:10, type: :binary},     #TPDU
      msg_head: {length:12, type: :ascii},  #报文头
      msg_type: {length:4, type: :bcd},     #消息类型
      bit_map: {length:16, type: :ascii},   #位元表
      account_len: {length:2, type: :bcd_byte},  #手机号+银行卡号的长度
      phone: {length:11,  type: :bcd},  #手机号
      card: {length: :account_length, type: :bcd_even},  #卡号
      trade_id: {length:6,  type: :bcd},  #交易处理码
      price: {length:12,  type: :bcd},  #交易金额
      trade_ind: {length:6,  type: :bcd},  #收单方系统跟踪号，交易流水
      trade_time: {length:6, type: :bcd},  #收单方所在地时间，交易时间
      trade_date: {length:8, type: :bcd},  #收单方所在地日期，交易日期
      refer_id: {length:24, type: :ascii_convert},  #检索参考号，POS中心系统流水号/交易参考号
      resp_code: {length:4, type: :ascii_convert},  #应答码
      pos_ind: {length:16, type: :ascii_convert}, #收单方终端标识码，POS终端号
      shop_ind: {length:30, type: :ascii_convert} #受卡方标识码，商户号
    }

    @data_hash.clear if @data_hash
    @data_result.clear if @data_result

    @data_hash = decode decode_string,decode_hash
    return unless @data_hash
    puts "decode hash is #{@data_hash}\n"

    # response = RestClient.post $dest_addr,@data_hash
    # if response.code = 200
    #   @data_hash[:resp_code] = "00"
    # else
    #   @data_hash[:resp_code] = "01"
    # end

    #编码时需要加上应答码两个字节,用于调试
    @data_hash[:resp_code] = "00"
    @data_result = encode @data_hash,decode_hash
  end
end

config_path = "../config/config.xml"
doc = Nokogiri::XML(open(config_path))
ip_addr = doc.search("IPAddr").first.content
port = doc.search("Port").first.content
$dest_addr = doc.search("DestAddr").first.content

server = TCPServer.new port
Thin::Server.start do
  loop do
    Thread.start(server.accept) do |client|
      allinpay = Allinpay.new
      data = client.gets
      data = data[0..-2]

      begin
        result = allinpay.process data
        client.puts result
      rescue Exception => e
        puts "Exception is #{e}"
      end
      
      # client.close
    end
  end
end
