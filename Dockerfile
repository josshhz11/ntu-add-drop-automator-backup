# Use an official Python runtime as a parent image
FROM python:3.9-slim AS base

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
FROM base AS chrome-installer
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg

# 2. Set up the Google Chrome repository using the keyring
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# 3. Install Google Chrome Stable
RUN apt-get update && apt-get install -y --no-install-recommends \
    google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# 4. Remove any existing ChromeDriver to avoid conflicts
RUN rm -f /usr/local/bin/chromedriver

# 5. Get EXACT Chrome version and download matching ChromeDriver
RUN CHROME_VERSION=$(google-chrome --version | sed 's/Google Chrome //' | sed 's/ .*//') && \
    echo "Chrome version: $CHROME_VERSION" && \
    echo "Downloading ChromeDriver version: $CHROME_VERSION..." && \
    wget -O /tmp/chromedriver.zip "https://storage.googleapis.com/chrome-for-testing-public/$CHROME_VERSION/linux64/chromedriver-linux64.zip" && \
    unzip /tmp/chromedriver.zip -d /tmp/ && \
    mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver* && \
    echo "=== INSTALLED VERSIONS ===" && \
    echo "Chrome: $(google-chrome --version)" && \
    echo "ChromeDriver: $(chromedriver --version)"

# 6. Set display (optional for headless operations)
ENV DISPLAY=:99

# 7. Copy requirements.txt and install Python dependencies
FROM chrome-installer AS final
COPY requirements.txt /app/
WORKDIR /app
RUN pip install --no-cache-dir -r requirements.txt

# 8. Copy your application code into the container
COPY . .

# 9. Expose port 5000 for FastAPI
EXPOSE 5000

# 10. Command to start FastAPI with Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
