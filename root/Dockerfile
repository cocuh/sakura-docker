FROM python:3.5-alpine
MAINTAINER cocuh <cocuh.kk at gmail.com>

RUN apk update
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r requirements.txt

COPY app /usr/src/app 

CMD ["/usr/local/bin/gunicorn", "-w", "2", "-b", ":8000", "app:app"]
