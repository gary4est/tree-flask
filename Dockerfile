FROM python:3.12-alpine
ADD ./app.py /app.py
ADD ./app_version.txt /app_version.txt
ADD ./commit_id.txt /commit_id.txt
ADD ./requirements.txt /requirements.txt
RUN pip install -r /requirements.txt
EXPOSE 8080
ENV PORT=8080
CMD ["python", "/app.py"]