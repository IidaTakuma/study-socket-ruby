require 'socket'
require 'json'

HOST_ADDRESS = '127.0.0.1' # localhost
HOST_PORT = 12345
LOCAL_ADDRESS = '127.0.0.1'
CRLF = "\r\n"

def main
  3.times do |i|
    Thread.new {
      sock = TCPSocket.open(HOST_ADDRESS, HOST_PORT, local_host=LOCAL_ADDRESS)
      sock.write(build_req_header)

      response_data = ''

      # read header
      while line = sock.gets
        break if line == CRLF
        response_data << line
      end

      # read body
      while line = sock.gets
        break if line == CRLF
        response_data << line
      end

      output_sock_info(sock, 'client')

      puts '[begin]response data'
      puts response_data
      puts "[end]response data\n\n"
      sock.close
    }
    sleep(0.1) # sleepを挟まないとsocketの作成でコケる
  end
end

def build_req_header
  <<~HEADER
    GET / HTTP/1.1
    User-Agent: client.rb made by iida
    Connection: keep-alive
    #{CRLF}
  HEADER
end

def output_sock_info(sock, name)
  puts "[begin] #{name} socket info"
  # file descripter, listen address, listen port はソケットを作成した時点で登録されている.
  puts "- file descriptor No: #{sock.fileno}"
  puts "- listen address: #{sock.local_address.ip_address}"
  puts "- listen port: #{sock.local_address.ip_port}"

  # 接続先がないと情報を出力できないので例外処理
  begin
    puts "- remote address: #{sock.remote_address.ip_address}"
  rescue Errno::ENOTCONN
    puts "- remote address: none..."
  end

  begin
    puts "- remote port: #{sock.remote_address.ip_port}"
  rescue Errno::ENOTCONN
    puts "- remote port: none..."
  end

  puts "[end] #{name} socket info\n\n"
  nil
end

main
