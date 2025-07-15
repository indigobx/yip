import http.server
import socketserver
import json
import datetime
import os
import time

PORT = 58080
DATA_DIR = "./projectile-data"
os.makedirs(DATA_DIR, exist_ok=True)

# Глобальные переменные для хранения состояния
last_timestamp = 0
current_file_path = None


class JSONRequestHandler(http.server.BaseHTTPRequestHandler):
  def do_POST(self):
    global last_timestamp, current_file_path

    content_length = int(self.headers.get('Content-Length', 0))
    body = self.rfile.read(content_length)
    try:
      data = json.loads(body)
      if 'kind' in data and data['kind'] == 'projectile':
        now = time.time() * 1000  # текущее время в мс
        if (now - last_timestamp > 1000) or current_file_path is None:
          timestamp_str = datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S-%f')[:-3]
          current_file_path = os.path.join(DATA_DIR, f"{timestamp_str}.jsonl")
        
        with open(current_file_path, "a", encoding="utf-8") as f:
          f.write(json.dumps(data, ensure_ascii=False) + "\n")
        
        last_timestamp = now

        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"status": "ok"}')
      else:
        print('Wrong kind')
        self.send_response(400)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"status": "wrong json"}')
    except json.JSONDecodeError:
      print("Wrong JSON")
      self.send_response(400)
      self.end_headers()

  def log_message(self, format, *args):
    return  # отключаем логгирование


if __name__ == "__main__":
  print(f"Server started on port {PORT}")
  with socketserver.TCPServer(("", PORT), JSONRequestHandler) as httpd:
    httpd.serve_forever()
