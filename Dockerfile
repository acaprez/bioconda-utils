FROM condaforge/linux-anvil-comp7
# Pretend we'd have C.UTF-8: Just copy en_US.UTF-8
RUN localedef -i en_US -f UTF-8 C.UTF-8
RUN sudo -n yum install -y openssh-clients && \
    sudo -n yum clean all && \
    sudo -n rm -rf /var/cache/yum/*
RUN mkdir -p /tmp/repo/bioconda_utils/
COPY ./bioconda_utils/bioconda_utils-requirements.txt /tmp/repo/bioconda_utils/
ENV PATH="/opt/conda/bin:${PATH}"
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    { conda config --remove repodata_fns current_repodata.json || true ; } && \
    conda config --prepend repodata_fns repodata.json && \
    conda config --set auto_update_conda False
RUN : 'Make sure we get the (working) conda we want before installing the rest.' && \
    sed -nE \
        -e 's/\s*#.*$//' \
        -e 's/^(conda([><!=~ ].+)?)$/\1/p' \
        /tmp/repo/bioconda_utils/bioconda_utils-requirements.txt \
        | xargs -r conda install -y
RUN conda install -y --file /tmp/repo/bioconda_utils/bioconda_utils-requirements.txt
RUN conda clean -y -it
COPY . /tmp/repo
RUN pip install /tmp/repo

ENTRYPOINT [ "/opt/conda/bin/tini", "--", "/tmp/repo/docker-entrypoint" ]
