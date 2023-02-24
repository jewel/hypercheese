FROM python:3.8-slim

WORKDIR /opt/app

RUN apt-get update && apt-get install ffmpeg libsm6 libxext6 wget -y \
   && apt-get clean

COPY requirements.txt .

RUN pip3 install -r requirements.txt && pip3 cache purge
RUN mkdir -p /root/.deepface/weights && wget -q https://github.com/serengil/deepface_models/releases/download/v1.0/retinaface.h5 && mv retinaface.h5 /root/.deepface/weights

COPY app.py .

CMD ["flask", "run", "--host=0"]
EXPOSE 5000
