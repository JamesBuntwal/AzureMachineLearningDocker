FROM mcr.microsoft.com/azureml/openmpi5.0-ubuntu24.04:20250414.v1

WORKDIR /

# ------------------------------------------------------------------------------
#    Create required variables
# ------------------------------------------------------------------------------
ENV PROJECT_NAME=<PROJECT NAME HERE>
ENV CONDA_PREFIX=/azureml-envs/$PROJECT_NAME
ENV CONDA_DEFAULT_ENV=$CONDA_PREFIX
ENV PATH=$CONDA_PREFIX/bin:$PATH
# This is needed for mpi to locate libpython
ENV LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH 



# ------------------------------------------------------------------------------
#    File dependencies
# ------------------------------------------------------------------------------
COPY conda_dependencies.yaml .
COPY pip_requirements.txt .



# ------------------------------------------------------------------------------
#    Update package lists and reinstall system OpenSSL & OpenSSH
# ------------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install --reinstall -y openssl libssl-dev openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*



# ------------------------------------------------------------------------------
#    Install Microsoft ODBC Driver 18 for SQL Server (Ubuntu 24.04)
# ------------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y \
    curl gnupg2 ca-certificates apt-transport-https \
    unixodbc unixodbc-dev \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg \
    && printf "Types: deb\nURIs: https://packages.microsoft.com/ubuntu/24.04/prod/\nSuites: noble\nComponents: main\nSigned-By: /etc/apt/keyrings/microsoft.gpg\n" \
    > /etc/apt/sources.list.d/microsoft-prod.sources \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*



# ------------------------------------------------------------------------------
#    Create conda environment
#    (only conda deps, including ruamel.yaml)
# ------------------------------------------------------------------------------
RUN conda env create -p $CONDA_PREFIX -f conda_dependencies.yaml -q \
    && rm conda_dependencies.yaml



# ------------------------------------------------------------------------------
#    Install pip packages without pulling their deps
#    (Azure and some weird ones where the deps mess up the build)
# ------------------------------------------------------------------------------
RUN conda run -p $CONDA_PREFIX pip install --no-deps -r pip_requirements.txt \
    && conda run -p $CONDA_PREFIX pip cache purge \
    && conda clean -a -y \
    && rm pip_requirements.txt


