#!/bin/bash
# setup-connectors.sh - Download and extract all three Kafka Connect plugins (FIXED)

set -e

PROJECT_DIR="$(pwd)"
CONNECTORS_DIR="$PROJECT_DIR/connectors"

echo "🚀 Setting up Kafka Connect plugins..."
echo "📁 Project directory: $PROJECT_DIR"

# Create connectors directory
echo "📁 Creating connectors directory..."
mkdir -p "$CONNECTORS_DIR"
cd "$CONNECTORS_DIR"

echo "📂 Working in: $(pwd)"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to verify file is valid gzip
verify_gzip() {
    local file="$1"
    if file "$file" | grep -q "gzip compressed data"; then
        return 0
    else
        echo "❌ File $file is not a valid gzip archive"
        file "$file"
        return 1
    fi
}

# Function to verify file is valid zip
verify_zip() {
    local file="$1"
    if file "$file" | grep -q -E "(Zip archive|ZIP)"; then
        return 0
    else
        echo "❌ File $file is not a valid zip archive"
        file "$file"
        return 1
    fi
}

# Function to download with retry and validation
download_file() {
    local url="$1"
    local filename="$2"
    local filetype="$3"  # "gzip" or "zip"
    local max_retries=3
    local retry=0

    while [ $retry -lt $max_retries ]; do
        echo "⬇️  Downloading: $filename (attempt $((retry + 1))/$max_retries)"

        # Remove any existing corrupted file
        [ -f "$filename" ] && rm -f "$filename"

        # Download with comprehensive options
        if curl -L --fail --show-error --progress-bar \
                --retry 2 --retry-delay 3 \
                --connect-timeout 30 --max-time 300 \
                --user-agent "Mozilla/5.0 (Linux x86_64; compatible)" \
                --header "Accept: application/octet-stream" \
                -o "$filename" \
                "$url"; then

            # Verify the downloaded file
            if [ "$filetype" = "gzip" ] && verify_gzip "$filename"; then
                echo "✅ Successfully downloaded and verified: $filename"
                return 0
            elif [ "$filetype" = "zip" ] && verify_zip "$filename"; then
                echo "✅ Successfully downloaded and verified: $filename"
                return 0
            else
                echo "⚠️  Downloaded file failed verification, retrying..."
                rm -f "$filename"
            fi
        else
            echo "⚠️  Download failed, retrying..."
        fi

        retry=$((retry + 1))
        [ $retry -lt $max_retries ] && sleep 5
    done

    echo "❌ Failed to download $filename after $max_retries attempts"
    return 1
}

# Check for required tools
echo "🔍 Checking for required tools..."
if ! command_exists curl; then
    echo "❌ curl is required but not installed. Please install curl and try again."
    exit 1
fi

if ! command_exists tar; then
    echo "❌ tar is required but not installed. Please install tar and try again."
    exit 1
fi

if ! command_exists unzip; then
    echo "❌ unzip is required but not installed. Please install unzip and try again."
    exit 1
fi

if ! command_exists file; then
    echo "❌ file command is required but not installed. Please install file and try again."
    exit 1
fi

echo "✅ All required tools found"

# 1) Download Debezium PostgreSQL Connector
echo ""
echo "📦 [1/3] Downloading Debezium PostgreSQL Connector (v2.4.0.Final)..."
DEBEZIUM_URL="https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.4.0.Final/debezium-connector-postgres-2.4.0.Final-plugin.tar.gz"
DEBEZIUM_FILE="debezium-connector-postgres-2.4.0.Final-plugin.tar.gz"

if [ ! -d "debezium-connector-postgres" ]; then
    if ! download_file "$DEBEZIUM_URL" "$DEBEZIUM_FILE" "gzip"; then
        echo "❌ Failed to download Debezium connector"
        exit 1
    fi

    echo "📂 Extracting Debezium connector..."
    if tar -xzf "$DEBEZIUM_FILE"; then
        echo "✅ Debezium PostgreSQL connector extracted"
    else
        echo "❌ Failed to extract Debezium connector"
        exit 1
    fi
else
    echo "✅ Debezium PostgreSQL connector already installed"
fi

echo ""
echo "📦 Installing SpoolDir connector from Confluent Hub..."

SPOOLDIR_VER="${SPOOLDIR_VER:-2.0.70}"   # pick a 2.x version; 2.0.70 is current
SPOOLDIR_COORD="confluentinc/kafka-connect-spooldir:${SPOOLDIR_VER}"

if [ ! -d "confluentinc-kafka-connect-spooldir" ]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker not found; download the ZIP from Confluent Hub and unzip here:"
    echo "   https://www.confluent.io/hub/confluentinc/kafka-connect-spooldir"
    exit 1
  fi

  VOL_OPTS="rw"
  if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" = "Enforcing" ]; then
    VOL_OPTS="rw,Z"
  fi

  docker run --rm --user 0:0 \
    -v "${CONNECTORS_DIR}:/plugins:${VOL_OPTS}" \
    confluentinc/cp-kafka-connect:7.4.0 \
    bash -lc 'mkdir -p /plugins && chmod 0777 /plugins && \
              confluent-hub install --no-prompt --component-dir /plugins '"${SPOOLDIR_COORD}"

  [ -d "confluentinc-kafka-connect-spooldir" ] \
    && echo "✅ SpoolDir installed to $(pwd)/confluentinc-kafka-connect-spooldir" \
    || { echo "❌ SpoolDir install failed"; exit 1; }
else
  echo "✅ SpoolDir already present, skipping"
fi

# --- S3 Sink (install via Confluent Hub client in Docker; robust perms/SELinux) ---
echo ""
echo "📦 [3/3] Installing Confluent S3 Sink via Confluent Hub client in Docker..."

S3_VER="${S3_VER:-10.5.24}"
S3_COORD="confluentinc/kafka-connect-s3:${S3_VER}"

if [ ! -d "confluentinc-kafka-connect-s3" ]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker not found. Download the ZIP from Confluent Hub and unzip here:"
    echo "   https://www.confluent.io/hub/confluentinc/kafka-connect-s3"
    exit 1
  fi

  # Add :Z on SELinux hosts so the container can write to the bind mount
  VOL_OPTS="rw"
  if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" = "Enforcing" ]; then
    VOL_OPTS="rw,Z"
  fi

  echo "🚚 Using Docker to run: confluent-hub install ${S3_COORD}"
  docker run --rm \
    --user 0:0 \
    -v "${CONNECTORS_DIR}:/plugins:${VOL_OPTS}" \
    confluentinc/cp-kafka-connect:7.4.0 \
    bash -lc 'mkdir -p /plugins && chmod 0777 /plugins && \
              confluent-hub install --no-prompt --component-dir /plugins '"${S3_COORD}"

  if [ -d "confluentinc-kafka-connect-s3" ]; then
    echo "✅ S3 sink installed to $(pwd)/confluentinc-kafka-connect-s3"
  else
    echo "⚠️  Online install failed. Trying offline ZIP if present..."
    if ls confluentinc-kafka-connect-s3-*.zip >/dev/null 2>&1; then
      ZIP=$(ls confluentinc-kafka-connect-s3-*.zip | head -1)
      echo "📦 Installing from $ZIP"
      unzip -oq "$ZIP"
    else
      echo "❌ No offline ZIP found. Download from Confluent Hub and place it here, then re-run."
      exit 1
    fi
  fi
else
  echo "✅ S3 sink already present, skipping"
fi



# Clean up downloaded archives
echo ""
echo "🧹 Cleaning up downloaded archives..."
rm -f "$DEBEZIUM_FILE" "$SPOOLDIR_FILE" "$S3_FILE"

# Show final directory structure
echo ""
echo "📋 Final connector directory structure:"
echo "$(pwd)"
find . -maxdepth 1 -type d ! -name '.' | sed 's|^\./|├── |' | sort

# Verify the key connector classes exist
echo ""
echo "🔍 Verifying connector installations..."

DEBEZIUM_JAR=$(find . -name "*debezium-connector-postgres*.jar" -type f | head -1)
SPOOLDIR_JAR=$(find . -name "*kafka-connect-spooldir*.jar" -type f | head -1)
S3_JAR=$(find . -name "*kafka-connect-s3*.jar" -type f | head -1)

if [ -n "$DEBEZIUM_JAR" ]; then
    echo "✅ Debezium PostgreSQL connector: Found ($DEBEZIUM_JAR)"
else
    echo "❌ Debezium PostgreSQL connector: NOT FOUND"
fi

if [ -n "$SPOOLDIR_JAR" ]; then
    echo "✅ SpoolDir connector: Found ($SPOOLDIR_JAR)"
else
    echo "❌ SpoolDir connector: NOT FOUND"
fi

if [ -n "$S3_JAR" ]; then
    echo "✅ Confluent S3 connector: Found ($S3_JAR)"
else
    echo "❌ Confluent S3 connector: NOT FOUND"
fi

# Final success check
TOTAL_CONNECTORS=0
[ -n "$DEBEZIUM_JAR" ] && TOTAL_CONNECTORS=$((TOTAL_CONNECTORS + 1))
[ -n "$SPOOLDIR_JAR" ] && TOTAL_CONNECTORS=$((TOTAL_CONNECTORS + 1))
[ -n "$S3_JAR" ] && TOTAL_CONNECTORS=$((TOTAL_CONNECTORS + 1))

echo ""
if [ $TOTAL_CONNECTORS -eq 3 ]; then
    echo "🎉 All 3 connectors installed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Start your Docker Compose stack: docker-compose up -d"
    echo "2. Wait for services to be ready (~60 seconds)"
    echo "3. Verify plugins are loaded: curl -s http://localhost:8083/connector-plugins | jq -r '.[].class' | grep -E '(Postgres|SpoolDir|S3)'"
    echo "4. Deploy your connector configurations"
else
    echo "⚠️  Only $TOTAL_CONNECTORS out of 3 connectors installed successfully"
    echo "Please check the error messages above and retry"
    exit 1
fi

cd "$PROJECT_DIR"