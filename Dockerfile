FROM python:3.9-slim-buster

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED 1

ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" python \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" python
WORKDIR /home/python

COPY --chown=python:python requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

# 시스템 의존성 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    curl \
    gnupg \
    libnss3 \
    libgconf-2-4 \
    libxi6 \
    libxcomposite1 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libxshmfence1 \
    libgbm1 \
    fonts-liberation \
    libappindicator3-1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Chrome 131.0.6778.204 설치
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable=131.0.6778.204-1 \
    && rm -rf /var/lib/apt/lists/*

# ChromeDriver 설치 (131.0.6778.204 버전)
RUN wget -N https://storage.googleapis.com/chrome-for-testing-public/131.0.6778.204/linux64/chromedriver-linux64.zip \
    && unzip chromedriver-linux64.zip \
    && rm chromedriver-linux64.zip \
    && mv chromedriver-linux64/chromedriver /usr/local/bin/chromedriver \
    && chmod +x /usr/local/bin/chromedriver \
    && rm -rf chromedriver-linux64
    
# USER 변경은 반드시 pip 패키지 설치 스크립트 이후에 작성되어야 함
USER python:python
ENV PATH="/home/${USER}/.local/bin:${PATH}"
COPY --chown=python:python . .

ARG FLASK_ENV

ENV FLASK_ENV=${FLASK_ENV}

EXPOSE 5000

CMD ["gunicorn", "-b", "0.0.0.0:5000", "wsgi:app"]
