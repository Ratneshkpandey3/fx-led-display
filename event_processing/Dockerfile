FROM python:3.8-slim
WORKDIR /event_processing

COPY . /event_processing
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 5001
CMD ["python", "flask_app.py"]
