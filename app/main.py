from flask import Flask, request, jsonify
import logging
import os

app = Flask(__name__)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

users = {}
next_user_id = 1


def reset():
    global users
    users = {}
    global next_user_id
    next_user_id = 1


@app.route('/', methods=['GET'])
def greet():
    return jsonify({"message": "Hello, World!"})


@app.route('/health', methods=['GET'])
def health():
    logger.info("Healthcheck")
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
    logger.info(f"Created user {user_id}: {name}")
    return jsonify(user), 201


@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = users.get(user_id)
    if not user:
        logger.warning(f"User {user_id} not found")
        return jsonify({"error": "User not found"}), 404
    return jsonify(user)


@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    if user_id not in users:
        logger.warning(f"User {user_id} not found for deletion")
        return jsonify({"error": "User not found"}), 404
    deleted = users.pop(user_id)
    logger.info(f"Deleted user {user_id}: {deleted['name']}")
    return jsonify({"message": "User deleted"}), 200


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
