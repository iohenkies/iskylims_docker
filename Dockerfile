# General
FROM ubuntu:18.04

# Updates
RUN apt-get update && apt-get upgrade -y

# Essential software
RUN apt-get install -y build-essential \
    git \
    gnuplot \
    libbz2-dev \
    libcairo2 \
    libcairo2-dev \
    libghc-zlib-dev \
    libpango1.0 \
    libpango1.0-dev \
    libsqlite3-dev \
    libssl1.0-dev \
    python3 \
    python3-pip \
    python3-virtualenv \
    sqlite3 \
    vim \
    wget

# Setup python virtualenv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m virtualenv --python=/usr/bin/python3 $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install mariadb to meet dependencies later on
RUN apt-get install -y software-properties-common
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
RUN add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.up.pt/pub/mariadb/repo/10.1/ubuntu bionic main'
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server \
    mariadb-client \
    libmariadb-dev \
    libmariadbclient-dev \
    libmariadbd-dev

# Interop requirment
WORKDIR /opt
RUN wget https://github.com/Illumina/interop/releases/download/v1.1.4/InterOp-1.1.4-Linux-GNU.tar.gz
RUN tar -xvf  InterOp-1.1.4-Linux-GNU.tar.gz
RUN ln -s InterOp-1.1.4-Linux-GNU interop

# Add user and group
RUN useradd django
RUN groupadd bioinfo
RUN usermod -a -G bioinfo django
RUN usermod -a -G bioinfo www-data

# Getting iSkyLIMS in check
WORKDIR /srv
RUN mkdir iSkyLIMS
RUN chown django:bioinfo iSkyLIMS/
RUN chmod 775 iSkyLIMS/
WORKDIR /srv/iSkyLIMS/
RUN git clone https://github.com/BU-ISCIII/iSkyLIMS.git .
RUN git submodule init
RUN git submodule update
RUN mkdir -p /srv/iSkyLIMS/documents/wetlab/tmp
RUN mkdir -p /srv/iSkyLIMS/documents/drylab
RUN mkdir -p /srv/iSkyLIMS/logs

# Starting iSkyLIMS
RUN pip3 install -r conf/pythonPackagesRequired.txt
RUN django-admin startproject iSkyLIMS .
RUN /bin/bash -c 'grep ^SECRET iSkyLIMS/settings.py > ~/.secret'

# Copying config files and script
COPY ./conf/settings.py /srv/iSkyLIMS/iSkyLIMS/
COPY ./conf/urls.py /srv/iSkyLIMS/iSkyLIMS/
COPY ./conf/index_file /srv/iSkyLIMS/documents/wetlab/
COPY ./conf/wetlab_config.py /srv/iSkyLIMS/iSkyLIMS_wetlab/
COPY ./conf/drylab_config.py /srv/iSkyLIMS/iSkyLIMS_drylab/
COPY ./conf/settings_zinnia.py /opt/venv/lib/python3.6/site-packages/zinnia/settings.py
COPY ./conf/admin_zinnia.py /opt/venv/lib/python3.6/site-packages/zinnia/admin.py
COPY ./scripts/migrations /srv/iSkyLIMS/
RUN chmod 750 migrations
RUN sed -i "/^SECRET/c\\$(cat ~/.secret)" iSkyLIMS/settings.py

# Replacing old Django references
RUN sed -i "s/django.core.urlresolvers/django.urls/g" /opt/venv/lib/python3.6/site-packages/zinnia/admin.py
RUN sed -i "s/django.core.urlresolvers/django.urls/g" /opt/venv/lib/python3.6/site-packages/crispy_forms/tests/test_layout.py
RUN sed -i "s/django.core.urlresolvers/django.urls/g" /opt/venv/lib/python3.6/site-packages/crispy_forms/tests/test_form_helper.py
RUN sed -i "s/django.core.urlresolvers/django.urls/g" /opt/venv/lib/python3.6/site-packages/crispy_forms/helper.py
RUN sed -i "s/django.core.urlresolvers/django.urls/g" /opt/venv/lib/python3.6/site-packages/zinnia_wymeditor/admin.py
RUN sed -i "s/django.core.urlresolvers/django.urls/g" /opt/venv/lib/python3.6/site-packages/django_extensions/management/shells.py
RUN sed -i "s/django.core.urlresolvers/django.urls/g" /opt/venv/lib/python3.6/site-packages/django_extensions/management/commands/show_urls.py
RUN sed -i "s/django.core.urlresolvers/django.urls/g" /opt/venv/lib/python3.6/site-packages/django_extensions/admin/widgets.py

# Expose and run
EXPOSE 8000
CMD python manage.py runserver 0:8000
