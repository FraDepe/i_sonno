from flask import Flask, request
import datetime

app = Flask(__name__)

@app.route('/data', methods=['POST'])
def receive_data():
    data = request.get_json()
    print(f"[{datetime.datetime.now()}] Received data: {data}")
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)