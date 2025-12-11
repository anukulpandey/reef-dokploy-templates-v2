import os
import uuid
import subprocess
from flask import Flask, request, jsonify, send_file

app = Flask(__name__)

OUTPUT_DIR = "/output"

def run_cmd(cmd):
    print("RUN:", cmd)
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout, result.stderr, result.returncode


@app.route("/generate", methods=["GET"])
def generate():
    required = ["v1addr", "v1seed", "v2addr", "v2seed", "v3addr", "v3seed"]
    for r in required:
        if r not in request.args:
            return jsonify({"error": f"Missing param: {r}"}), 400

    v1addr = request.args["v1addr"]
    v1seed = request.args["v1seed"]

    v2addr = request.args["v2addr"]
    v2seed = request.args["v2seed"]

    v3addr = request.args["v3addr"]
    v3seed = request.args["v3seed"]

    # Create unique folder
    folder_id = str(uuid.uuid4())
    folder_path = f"{OUTPUT_DIR}/{folder_id}"
    os.makedirs(folder_path, exist_ok=True)

    # 1️⃣ Generate plain spec
    out_plain = f"{folder_path}/local-chain-spec.json"
    cmd = f"reef-node build-spec --chain testnet-new --disable-default-bootnode > {out_plain}"
    run_cmd(cmd)

    # 2️⃣ Update spec using script
    out_updated = f"{folder_path}/local-chain-spec-updated.json"
    cmd = (
        f"/workspace/scripts/update-spec.sh "
        f"--v1_addr {v1addr} --v1_sec {v1seed} "
        f"--v2_addr {v2addr} --v2_sec {v2seed} "
        f"--v3_addr {v3addr} --v3_sec {v3seed} "
        f"--input {out_plain} --output {out_updated}"
    )
    run_cmd(cmd)

    # 3️⃣ Generate RAW spec
    out_raw = f"{folder_path}/local-chain-spec-raw.json"
    cmd = (
        f"reef-node build-spec --chain {out_updated} "
        f"--disable-default-bootnode --raw > {out_raw}"
    )
    run_cmd(cmd)

    return jsonify({
        "id": folder_id,
        "raw_spec_url": f"http://{request.host}/download/{folder_id}/local-chain-spec-raw.json",
        "folder": folder_id
    })


@app.route("/download/<folder>/<filename>", methods=["GET"])
def download(folder, filename):
    path = f"{OUTPUT_DIR}/{folder}/{filename}"

    if not os.path.exists(path):
        return jsonify({"error": "File not found"}), 404

    return send_file(path, as_attachment=True)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


app.run(host="0.0.0.0", port=8000)
