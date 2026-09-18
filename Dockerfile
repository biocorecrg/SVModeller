FROM mambaorg/micromamba:1.5.8

ARG VERSION=0.5.0
ENV SVMODELLER_VERSION=${VERSION}

LABEL org.opencontainers.image.title="SVModeller" \
      org.opencontainers.image.description="Simulator of synthetic human haplotypes containing embedded structural variants (SV)" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.opencontainers.image.source="https://github.com/biocorecrg/SVModeller"

USER root
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*

USER $MAMBA_USER

# Copy environment configuration
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/environment.yml

# Install conda dependencies into base environment
RUN micromamba install -y -n base -f /tmp/environment.yml && \
    micromamba clean --all --yes

# Set working directory
WORKDIR /app

# Clone GAPI repository directly into /app/GAPI
RUN git clone --depth 1 https://github.com/biocorecrg/GAPI.git /app/GAPI

# Add conda environment to PATH and /app to PYTHONPATH for GAPI resolution
ENV PATH="/opt/conda/bin:${PATH}"
ENV PYTHONPATH="/app:${PYTHONPATH}"

WORKDIR /data

CMD ["/bin/bash"]
