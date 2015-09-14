$LOAD_PATH.unshift(File.dirname(__FILE__))
require "denong_allinpay/version"
require "parse_string.rb"
require "nokogiri"
require "rest_client"
require 'thin'
require "socket"

module Allinpay
  include CodeProcessor
  def receive_data data
    data.chomp!
    changed_data = data.unpack("H*").join.upcase
    return if changed_data == "000430303030"
    puts "Time is #{DateTime.now}, changed_data is #{changed_data}, its size is #{changed_data.size}\n"
    data_result = data_process changed_data if changed_data
    send_data "#{data_result}"
    puts "-----end-----"
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
      phone: {length:12,  type: :bcd},  #手机号
      card: {length: :account_length, type: :bcd_even},  #卡号
      trade_id: {length:6,  type: :bcd},  #交易处理码
      price: {length:12,  type: :bcd},  #交易金额
      trade_ind: {length:6,  type: :bcd},  #收单方系统跟踪号，交易流水
      trade_time: {length:6, type: :bcd},  #收单方所在地时间，交易时间
      trade_date: {length:4, type: :bcd},  #收单方所在地日期，交易日期
      refer_id: {length:24, type: :ascii_convert},  #检索参考号，POS中心系统流水号/交易参考号
      resp_code: {length:4, type: :ascii_convert},  #应答码
      pos_ind: {length:16, type: :ascii_convert}, #收单方终端标识码，POS终端号
      shop_ind: {length:30, type: :ascii_convert} #受卡方标识码，商户号
    }

    @data_hash.clear if @data_hash
    return unless decode_string
    

    begin
      @data_hash = decode decode_string,decode_hash
    rescue Exception => e
      puts "decode exception is #{e}"
    end
    return unless @data_hash
    puts "decode hash is #{@data_hash}\n"
    send_hash = { tl_trade: @data_hash}

    url = ""
    if $dest_port
      url = "#{$dest_addr}:#{$dest_port}/tl_trades"
    else
      url = "#{$dest_addr}/tl_trades"
    end

    begin
      response = RestClient.post url, send_hash, content_type: "json", accept: "json"
    rescue Exception => e
      puts "Exception is #{e}"
    end
    
    if !response.nil? && response.code == 201
      @data_hash[:resp_code] = "00"
    else
      @data_hash[:resp_code] = "01"
    end

    #编码时需要加上应答码两个字节,用于调试
    # @data_hash[:resp_code] = "00"
    encode @data_hash, decode_hash
  end
end

config_path = "../config/config.xml"
doc = Nokogiri::XML(open(config_path))
ip_addr = doc.search("IPAddr").first.content
port = doc.search("Port").first.content
$dest_addr = doc.search("DestAddr").first.content
$dest_port = doc.search("DestPort").first.content

puts "ip address is #{ip_addr}, port is #{port}"

Thin::Server.start do
  EM.run { EM.start_server ip_addr, port, Allinpay }
end