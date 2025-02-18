from flask import Flask, send_from_directory

application = Flask(__name__, static_folder='static')

@application.route('/')
def serve_index():
    return send_from_directory('static', 'index.html')

if __name__ == '__main__':
    application.run(host='0.0.0.0', port=8080)
