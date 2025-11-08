from flask import Flask, request, jsonify
from flask_cors import CORS
import boto3
from datetime import datetime
from dotenv import load_dotenv
import os

load_dotenv()  # Load .env values

app = Flask(__name__)
CORS(app)

AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY")
AWS_REGION = os.getenv("AWS_REGION")
AWS_BUCKET = os.getenv("AWS_BUCKET")

s3 = boto3.client(
    "s3",
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=AWS_REGION
)

@app.route("/generate-upload-url", methods=["POST"])
def generate_upload_url():
    file_type = request.form.get("file_type")
    file_name = request.form.get("file_name")

    if not file_type or not file_name:
        return jsonify({"error": "file_type and file_name required"}), 400

    ext = "jpg" if file_type == "image" else "mp3"
    key = f"uploads/{datetime.now().timestamp()}_{file_name}"
    mime_type = "image/jpeg" if file_type == "image" else "audio/mpeg"

    upload_url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": AWS_BUCKET,
            "Key": key,
            "ContentType": mime_type
        },
        ExpiresIn=300
    )

    public_url = f"https://{AWS_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{key}"

    return jsonify({
        "upload_url": upload_url,
        "public_url": public_url,
        "file_key": key
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
