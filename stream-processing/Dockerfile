FROM python:3.9.13-slim-buster as poetry
WORKDIR /stream_processing
ENV POETRY_VERSION=1.8.3

RUN pip install --no-cache-dir "poetry==$POETRY_VERSION"
COPY pyproject.toml ./
RUN poetry install --no-root --no-dev

RUN poetry export -f requirements.txt --output requirements.txt --without-hashes


FROM python:3.9.13-slim
WORKDIR /stream_processing
COPY --from=poetry /stream_processing/requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY . .


EXPOSE 5001
CMD ["python", "flask_app.py"]
