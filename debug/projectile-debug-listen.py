import http.server
import socketserver
import json
import datetime

PORT = 58080
request_count = 0


class JSONRequestHandler(http.server.BaseHTTPRequestHandler):
  def do_POST(self):
    global request_count
    content_length = int(self.headers.get('Content-Length', 0))
    body = self.rfile.read(content_length)
    try:
      data = json.loads(body)
      self.send_response(200)
      self.send_header('Content-Type', 'application/json')
      self.end_headers()
      self.wfile.write(b'{"status": "ok"}')
      with open(f"./proj_v2/{request_count}_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.json", "w") as f:
        json.dump(data, f)
      request_count += 1
    except json.JSONDecodeError:
      print("Wrong JSON")

  def log_message(self, format, *args):
    return  # Отключаем лишние логи


if __name__ == "__main__":
  with socketserver.TCPServer(("", PORT), JSONRequestHandler) as httpd:
    print(f"Server started on port {PORT}")
    httpd.serve_forever()
