
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHON_VERSION=3.10
ENV VLLM_CU_VERSION=118
ARG VLLM_TARGET_VERSION
ENV UV_HTTP_TIMEOUT=500
ENV UV_INDEX_STRATEGY="unsafe-best-match"


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    python${PYTHON_VERSION} \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    curl \
    ca-certificates \
    build-essential \
    libaio-dev && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    pip install --no-cache-dir --upgrade pip

RUN pip install --no-cache-dir uv

# workaround for [vllm-project/vllm@3fc9644](https://github.com/vllm-project/vllm/commit/3fc964433a84bad785d9d0656fd56195462321b8)
RUN if dpkg --compare-versions "${VLLM_TARGET_VERSION}" lt "0.10" ; then \
        echo "VLLM_TARGET_VERSION is less than 0.10, installing transformers<4.54.0"; \
        uv pip install --system "transformers<4.54.0"; \
    else \
        echo "VLLM_TARGET_VERSION is 0.10 or greater, skipping transformers<4.54.0 installation"; \
    fi

RUN VLLM_WHEEL_URL="https://github.com/vllm-project/vllm/releases/download/v${VLLM_TARGET_VERSION}/vllm-${VLLM_TARGET_VERSION}+cu${VLLM_CU_VERSION}-cp38-abi3-manylinux1_x86_64.whl" && \
    echo "Downloading VLLM wheel from: ${VLLM_WHEEL_URL}" && \
    uv pip install --system "${VLLM_WHEEL_URL}" \
    --extra-index-url https://download.pytorch.org/whl/cu${VLLM_CU_VERSION}


WORKDIR /app

ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
