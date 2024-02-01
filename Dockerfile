ARG BASE_IMAGE=""

####
## Stage 1 - Download and convert the notebook
####
FROM python:3.9-alpine3.19 AS notebook_autoconversion
RUN apk update && \
    apk add git

WORKDIR /home
RUN pip install --upgrade pip && \
    pip install nbformat==5.9.2

# Read all the arguments
ARG BASE_IMAGE
ARG PATH_TO_NOTEBOOK
ARG PATH_TO_REQUIREMENTS
ARG SECTIONS_TO_REMOVE
ARG NOTEBOOK_NAME
ARG GPU_FLAG
ARG PYTHON_VERSION

# Custom cache invalidation
ARG CACHEBUST=1

# All the layers bellow this will not be cached
RUN echo "${CACHEBUST}"

# Download the notebook
ADD $PATH_TO_NOTEBOOK ./${NOTEBOOK_NAME}

# Autoconvert the notebook
RUN git clone --branch reduce_code https://github.com/HenriquesLab/DL4MicEverywhere.git  && \
    python DL4MicEverywhere/.tools/notebook_autoconversion/transform.py -p . -n ${NOTEBOOK_NAME} -s ${SECTIONS_TO_REMOVE}  && \
    mv colabless_${NOTEBOOK_NAME} ${NOTEBOOK_NAME}  && \
    python DL4MicEverywhere/.tools/python_tools/create_docker_info.py "/home/docker_info.txt" "${BASE_IMAGE}" "${PATH_TO_NOTEBOOK}" "${PATH_TO_REQUIREMENTS}" \
       "${SECTIONS_TO_REMOVE}"  "${NOTEBOOK_NAME}" "${GPU_FLAG}" "${PYTHON_VERSION}"

####
## Stage 2 - Set the final image (install packages, python, python libraries)
####
FROM ${BASE_IMAGE} AS final

# Read all the arguments
ARG PATH_TO_NOTEBOOK=""
ARG PATH_TO_REQUIREMENTS=""
ARG SECTIONS_TO_REMOVE=""
ARG NOTEBOOK_NAME=""
ARG GPU_FLAG=""
ARG PYTHON_VERSION=""

# Set the language
ENV LANG=C.UTF-8

# Set timezone for Python installation
ENV TZ=Europe/Lisbon
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install an specific nodejs version (using NVM - Node Version Manager)
ENV NODE_VERSION=20.10.0
RUN apt-get update && \
    apt-get install -y curl && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION} && \
    . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION} && \
    . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

# Install common packages and nvidia-cuda-toolkit
RUN apt-get update && \
    apt-get install -y build-essential \
                       software-properties-common \
                       wget \ 
                       unzip \
                       git \
                       libsm6 \
                       libxext6 \
                       libopenmpi-dev \
                       libfreetype6-dev \
                       ffmpeg \
                       pkg-config && \
    if [ "$GPU_FLAG" -eq "1" ] ; then apt-get install -y nvidia-cuda-toolkit ; fi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Instal Python 
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python3-pip python${PYTHON_VERSION}-venv && \
    rm -rf /var/lib/apt/lists/* && \
    python${PYTHON_VERSION} -m pip install pip --upgrade && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 0 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 0

# Run nvidia-cudnn-cu11 for Python
RUN if [ "$GPU_FLAG" -eq "1" ] ; then pip install nvidia-cudnn-cu11==8.6.0.163 ; fi
# And export the environment variable LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH lib/:/usr/local/lib/python${PYTHON_VERSION}/dist-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH

# Set the working directory
WORKDIR /home 

# Install nbformat and jupyterlab
RUN pip install --upgrade pip && \
    if [  "$(printf '%s\n' "3.8" "${PYTHON_VERSION}" | sort -V | head -n1)" = "3.8" ] ; then \
        # For Python between 3.8 and 3.11
        pip install --no-cache-dir  nbformat==5.9.2 ; \ 
    else \
        # For Python 3.7 or lower
        pip install --no-cache-dir  nbformat==5.0.2 ; \
    fi && \
    if [  "$(printf '%s\n' "3.7" "${PYTHON_VERSION}" | sort -V | head -n1)" = "3.7" ] ; then \
        # For Python between 3.7 and 3.11
        pip install --no-cache-dir  ipywidgets==8.1.0 && \ 
        pip install --no-cache-dir  jupyterlab==3.6.0 ; \ 
    elif [  "$(printf '%s\n' "3.5" "${PYTHON_VERSION}" | sort -V | head -n1)" = "3.5" ] ; then \
        # For Python 3.4 or lower
        pip install --no-cache-dir  ipywidgets==7.8.1 && \ 
        pip install --no-cache-dir  jupyterlab==0.23.0 ; \ 
    else \
        # For Python 3.5 and 3.6
        pip install --no-cache-dir  ipywidgets==8.0.0a0 && \ 
        pip install --no-cache-dir  jupyterlab==2.3.2 ; \ 
    fi

# Custom cache invalidation
ARG CACHEBUST=1
# All the layers bellow this will not be cached
RUN echo "${CACHEBUST}"

# Download the notebook and requirements if they are not provided
ADD $PATH_TO_REQUIREMENTS ./requirements.txt

# Install the requirements and convert the notebook
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    rm requirements.txt
    
# Copy the converted notebook from stage 1
COPY --from=notebook_autoconversion /home/${NOTEBOOK_NAME} /home/docker_info.txt /home

ENV XLA_FLAGS=--xla_gpu_cuda_data_dir=/usr/lib/cuda

CMD bash