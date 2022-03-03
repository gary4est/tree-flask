FROM python:3.9.10-alpine3.15
ADD ./app.py /app.py
ADD ./app_version.txt /app_version.txt
ADD ./commit_id.txt /commit_id.txt
ADD ./requirements.txt /requirements.txt
RUN pip install -r /requirements.txt
#EXPOSE 5000
ENTRYPOINT ["python","/app.py"]