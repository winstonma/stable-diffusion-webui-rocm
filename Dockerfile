FROM ubuntu:jammy

SHELL ["/bin/bash", "-c"]  
ENV PORT=7860 \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    REQS_FILE='requirements.txt' \
    COMMANDLINE_ARGS='' 

WORKDIR /opt

RUN apt -y update

RUN apt-get install -y --no-install-recommends libstdc++-12-dev \
    ca-certificates \
    wget \
    gnupg2 \
    gawk \
    curl \
    git \
    libglib2.0-0 \
    apt-utils \
    python3.10-venv \
    python3-pip \
    libxml2-utils \
    google-perftools

RUN apt-get autoremove -y && \
	apt-get clean -y && \
	rm -rf /var/lib/apt/lists/* && \
	python3 -m venv venv && \
	source venv/bin/activate && \
	ln -s /usr/bin/python3 /usr/bin/python && \
	python3 -m pip install --upgrade pip wheel

# Install AMD Driver
RUN FILENAME=$(curl https://repo.radeon.com/amdgpu-install/latest/ubuntu/jammy/ | grep deb | xmllint --html --format --xpath "string(//a/@href)" - ) \
    && TEMP_DEB="$(mktemp)" \
    && wget -O "$TEMP_DEB" https://repo.radeon.com/amdgpu-install/latest/ubuntu/jammy/"$FILENAME" \
    && dpkg -i "$TEMP_DEB" \
    && rm -f "$TEMP_DEB"

RUN amdgpu-install -y --usecase=rocm

# Add user to the render group if you're using Ubuntu20.04
RUN usermod -a -G render root

# To add future users to the video and render groups, run the following command:
RUN echo 'ADD_EXTRA_GROUPS=1' | sudo tee -a /etc/adduser.conf
RUN echo 'EXTRA_GROUPS=video' | sudo tee -a /etc/adduser.conf
RUN echo 'EXTRA_GROUPS=render' | sudo tee -a /etc/adduser.conf

# Install Pytorch
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.4.2

# Install Stable Diffusion WebUI
ARG APP=/sd

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui ${APP}

WORKDIR ${APP}

RUN pip install -r requirements_versions.txt

# Install Stable Diffusion Requirement file
COPY prepare_environment.py ${APP}
RUN python prepare_environment.py

# Install base model (Please add any additional model)
ADD https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors ${APP}/models/Stable-diffusion
 
EXPOSE ${PORT}

VOLUME [ "/sd/configs","/sd/models", "/sd/outputs","/sd/extensions", "/sd/plugins"]
ENTRYPOINT python -d launch.py --port "${PORT}"

	
	
	
	
	
	



