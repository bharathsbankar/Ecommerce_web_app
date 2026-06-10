# Stage 1: Build dependencies
FROM python:3.10-alpine AS builder

WORKDIR /app

RUN apk add --no-cache gcc musl-dev mariadb-dev python3-dev libffi-dev build-base

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Final runner
FROM python:3.10-alpine

WORKDIR /app

# Install runtime dependencies for mysqlclient
RUN apk add --no-cache mariadb-connector-c

# Copy installed site-packages from builder
COPY --from=builder /root/.local /root/.local
COPY . .

ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["sh", "-c", "python manage.py migrate && gunicorn auth_service.wsgi:application --bind 0.0.0.0:8000"]
