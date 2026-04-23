from flask import Flask, request, jsonify

app = Flask(__name__)

users = {}
next_user_id = 1

def reset():
    global users
    users.clear()
    global next_user_id
    next_user_id = 1

@app.route('/', methods=['GET'])
def greet():
    return jsonify({"message": "Hello, World!"})

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"}), 200

@app.route('/api/users', methods=['GET'])
def get_users():
    return jsonify({"users": list(users.values())})

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body must be JSON"}), 400
    name = data.get('name')
    if not name:
        return jsonify({"error": "Missing required field: name"}), 400
    global next_user_id
    user_id = next_user_id
    next_user_id += 1
    user = {"id": user_id, "name": name}
    users[user_id] = user
    return jsonify(user), 201

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = users.get(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(user)

@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    if user_id not in users:
        return jsonify({"error": "User not found"}), 404
    users.pop(user_id)
    return jsonify({"message": "User deleted"}), 200

if __name__ == '__main__':
    app.run(port=5000)
