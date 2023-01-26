FROM python:slim

RUN useradd project

WORKDIR /home/project

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY app app
COPY start.py ./
ENV FLASK_APP start.py

RUN chown -R project:project ./
USER project

EXPOSE 5000

CMD [ "gunicorn", "-w", "4", "--bind", "0.0.0.0:5000", "start:app"]