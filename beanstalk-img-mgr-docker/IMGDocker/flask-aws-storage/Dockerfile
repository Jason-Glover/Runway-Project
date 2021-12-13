FROM python:3.6.9

RUN groupadd flaskgroup && useradd -m -g flaskgroup -s /bin/bash flask

RUN mkdir -p /home/flask/app/web
RUN mkdir /home/flask/app/web/uploads
WORKDIR /home/flask/app/web

COPY requirements.txt /home/flask/app/web
RUN pip install --no-cache-dir -r requirements.txt

COPY . /home/flask/app/web

RUN chown -R flask:flaskgroup /home/flask

EXPOSE 5000
USER flask
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0"]
