ARG PYTHON_VERSION=3.9-slim
FROM python:${PYTHON_VERSION}

# Install utils
RUN apt -y update \
    && apt -y upgrade \
    && apt -y install curl wget gpg unzip git

# Install yc CLI
RUN curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash

# Install Terraform
ARG TERRAFORM_VERSION=1.4.6
RUN curl -sL https://hashicorp-releases.yandexcloud.net/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && install -o root -g root -m 0755 terraform /usr/local/bin/terraform \
    && rm -rf terraform terraform.zip

# Install dbt
ARG DBT_VERSION=1.7
RUN set -ex \
    && python -m pip install --upgrade pip setuptools \
    && python -m pip install --upgrade dbt-clickhouse~=${DBT_VERSION} numpy
ENV DBT_PROFILES_DIR=../dbt