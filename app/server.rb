require 'socket'
require 'json'

ADDRESS = '127.0.0.1' # localhost
PORT = 12345
CRLF = "\r\n"

def main
  begin
    listen_sock = Socket.tcp_server_sockets(ADDRESS, PORT) # サーバーLISTEN用のソケット作成

    puts "[info]server start.\n\n"

    # LISTEN用ソケットの情報を出力する
    output_sock_info(listen_sock[0], 'listener')

    # ここで作成するソケットは、接続要求してきたクライアントと通信をするためのソケット
    Socket.accept_loop(listen_sock) { |sock, client_addrinfo|
      Thread.start {
        begin
          puts "[info] sub process start.\n\n"
          output_sock_info(sock, 'sub process')

          req_method, req_header, req_body = read_request(sock)

          sleep(1) # 複数スレッドが同時に起動する状態を作るために

          sock.write(build_res_header)
          sock.write(build_res_body)
        ensure
          sleep(1)
          sock.close
        end
      }
    }
  ensure
    listen_sock.map(&:close)
  end
end

def read_request(sock)
  method = request_method(sock.gets)

  header = {}
  while line = sock.gets
    break if line == CRLF

    key, value = line.chomp.split(':')
    header[key] = value
  end

  body = ''
  if method == 'POST'
    while line = sock.gets
      p line
      break if line == CRLF
      body << line
    end
  end

  return [method, header, body]
end

def request_method(first_line)
  if first_line.include?('GET')
    'GET'
  elsif first_line.include?('POST')
    'POST'
  else
    nil
  end
end

# とりあえず固定のレスポンス
def build_res_header
  <<~HEADER
    HTTP/1.1 200 OK
    Content-Type: text/html;
    Connection: close
    #{CRLF}
  HEADER
end

# とりあえず固定のボディ
def build_res_body
  <<~BODY
    <h1>server response</h1>
    <p1>hello~</p1>
    #{CRLF}
  BODY
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
