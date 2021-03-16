FROM wheatstalk/makensis:latest

RUN dpkg --add-architecture i386 \ 
    && apt-get update \
    && apt-get install -y \
    perl libfile-copy-recursive-perl libfile-rsync-perl wget unzip git wine wine32 \
    && apt-get clean -y

WORKDIR /installer/3Di-additions
