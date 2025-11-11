# Use an official Python runtime as a parent image
FROM python:3.9-slim as base

# Install necessary system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    gnupg \
    curl \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    ca-certificates \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# 1. Add Google’s signing key using the recommended keyring method
FROM base as chrome-installer
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg

# 2. Set up the Google Chrome repository using the keyring
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# 3. Remove any existing ChromeDriver to avoid conflicts
RUN rm -f /usr/local/bin/chromedriver

# 4. Get latest stable ChromeDriver version first
RUN LATEST_CHROMEDRIVER=$(curl -s "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE") && \
    echo "Latest stable ChromeDriver version: $LATEST_CHROMEDRIVER" && \
    # Download ChromeDriver
    wget -O /tmp/chromedriver.zip "https://storage.googleapis.com/chrome-for-testing-public/$LATEST_CHROMEDRIVER/linux64/chromedriver-linux64.zip" && \
    unzip /tmp/chromedriver.zip -d /tmp/ && \
    mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver* && \
    # Now download matching Chrome version
    wget -O /tmp/chrome.zip "https://storage.googleapis.com/chrome-for-testing-public/$LATEST_CHROMEDRIVER/linux64/chrome-linux64.zip" && \
    unzip /tmp/chrome.zip -d /tmp/ && \
    mv /tmp/chrome-linux64/chrome /usr/bin/google-chrome && \
    chmod +x /usr/bin/google-chrome && \
    rm -rf /tmp/chrome* && \
    echo "Installed versions:" && \
    google-chrome --version && \
    chromedriver --version

# 5. Set display (optional for headless operations)
ENV DISPLAY=:99

# 6. Copy requirements.txt and install Python dependencies
FROM chrome-installer as final
COPY requirements.txt /app/
WORKDIR /app
RUN pip install --no-cache-dir -r requirements.txt

# 7. Copy your application code into the container
# Application code (ONLY THIS rebuilds on code changes)
COPY . .

# 8. Expose port 5000 for FastAPI
EXPOSE 5000

# 9. Command to start FastAPI with Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
