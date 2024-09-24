FROM python:3.9.13-slim-buster as poetry
WORKDIR /stream_processing
ENV POETRY_VERSION=1.8.3

RUN pip install --no-cache-dir "poetry==$POETRY_VERSION"
COPY pyproject.toml poetry.lock /stream_processing/
RUN poetry install --no-dev

RUN poetry export -f requirements.txt --output requirements.txt --without-hashes


FROM python:3.9.13-slim
WORKDIR /stream_processing
COPY --from=poetry /stream_processing/requirements.txt /stream_processing/

RUN pip install --no-cache-dir -r requirements.txt

COPY . /stream_processing/

EXPOSE 5001
CMD ["python", "stream_processing/flask_app.py"]
