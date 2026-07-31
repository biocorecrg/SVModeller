FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="SVModeller" \
      org.opencontainers.image.description="Simulator of synthetic human haplotypes containing embedded structural variants (SV)" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.opencontainers.image.source="https://github.com/REPBIO-LAB/SVModeller"

USER root
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*

USER $MAMBA_USER

# Copy environment configuration
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/environment.yml

# Install dependencies into base conda environment
RUN micromamba install -y -n base -f /tmp/environment.yml && \
    micromamba clean --all --yes

# Set working directory
WORKDIR /app

# Copy repository content
COPY --chown=$MAMBA_USER:$MAMBA_USER . /app

# Make python modules executable
USER root
RUN chmod +x /app/Module*.py /app/Additional_scripts/*.py

USER $MAMBA_USER

# Set environment PATH to include app directory and scripts
ENV PATH="/app:/app/Additional_scripts:${PATH}"

WORKDIR /data

CMD ["python3", "/app/Module1.py", "--help"]
