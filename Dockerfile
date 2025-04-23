# Starting image
FROM ubuntu:22.04

# Install prerequisites
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y \
    python3 \
    python3-pip \
    libpython3-dev \
    git \
    sudo \
    curl \
    gcc \
    cmake \
    python3-venv \
    time \
    wget \
    vim \
    bc \
    locales \
    dos2unix \
    bash-completion


RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create user
ENV USER=user
RUN useradd -m -G sudo -p "" user
RUN chsh -s /bin/bash user
# SWI packages no longer need the user's user
#USER ${USER}
ENV HOME=/home/${USER}

WORKDIR ${HOME}

# Install MeTTaLog

ENV METTALOG_DIR="${HOME}/metta-wam"
ENV PATH="${PATH}:${METTALOG_DIR}"

WORKDIR ${HOME}
# RUN git clone https://github.com/trueagi-io/metta-wam.git

RUN mkdir -p "${METTALOG_DIR}"
WORKDIR ${METTALOG_DIR}
# This COPY is in case we have made local changes 
#         so we dont have to commit to Github to test them out
COPY ./ ./
# get rid of copied venv that is probably using a whole different python anyways
RUN rm -rf ./venv/  
COPY ./INSTALL.sh ./INSTALL.sh
RUN mkdir -p  /home/user/.config/metta && touch /home/user/.config/metta/repl_history.txt

SHELL ["/bin/bash", "-c"]
RUN source ./INSTALL.sh --easy --allow-system-modifications

RUN mettalog --compile-only

#RUN swipl -l src/main/metta_interp.pl -g qcompile_mettalog


