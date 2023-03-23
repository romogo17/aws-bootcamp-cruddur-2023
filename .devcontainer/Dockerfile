ARG VARIANT="linux"
FROM mcr.microsoft.com/devcontainers/universal:2-${VARIANT}

# Install the PostgreSQL CLI
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | sudo tee  /etc/apt/sources.list.d/pgdg.list \
    && sudo apt update && sudo apt install -y postgresql-client-13 libpq-dev

# Install the AWS CLI
RUN TMP_DIR="$(mktemp -d)" \
    && cd "${TMP_DIR}" || exit 1 \
    && curl -fSsl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip -qq awscliv2.zip \
    && sudo ./aws/install --update \
    && rm awscliv2.zip

# Momento CLI
RUN TMP_DIR="$(mktemp -d)" \
    && cd "${TMP_DIR}" || exit 1 \
    && wget https://github.com/momentohq/momento-cli/releases/download/v0.36.0/momento-cli_0.36.0_amd64.deb \
    && sudo apt install "${TMP_DIR}/momento-cli_0.36.0_amd64.deb"

# Use Node.js v16
RUN nvm install v16