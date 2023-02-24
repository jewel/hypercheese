FROM python:3.8-slim

WORKDIR /opt/app

RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y \
   && apt-get clean

COPY requirements.txt .

RUN pip3 install -r requirements.txt && pip3 cache purge

COPY app.py .

CMD ["flask", "run", "--host=0"]
EXPOSE 5000
