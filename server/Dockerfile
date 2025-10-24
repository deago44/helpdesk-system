FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt
RUN mkdir -p /app/uploads
COPY . /app/
EXPOSE 8080
CMD python -c "import app; app.init_db()" && gunicorn -b 0.0.0.0:8080 app:app
