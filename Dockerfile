###########################################################################
# lilypond-base: minimal image for running lilypond and its scripts
###########################################################################
FROM emscripten/emsdk AS lilypond-base

## The fonts-texgyre package (the preferred default fonts) is not
## strictly required, since LilyPond can fall back on other fonts, but
## it is convenient to include in the base image so that it is
## consistently available in derived images.
##
## TODO: Don't install adduser? or remove it when we're finished with it?
##
RUN apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y \
    # adduser \
    fonts-texgyre \
    ghostscript \
    guile-3.0-dev \
    libpangoft2-1.0-0 \
    python-is-python3 \
    python3 \
    flex \
    libfl-dev \
    # sudo \
&& rm -rf /var/lib/apt/lists/*

# Add a non-root user who can run sudo without a password.
# RUN useradd -m -s /bin/bash user \
# && adduser user sudo \
# && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
# && sudo -u user touch ~user/.sudo_as_admin_successful

# USER user
RUN cat <<EOF >> ~/.bashrc
if [ "$TERM_PROGRAM" = "Apple_Terminal" ] ; then
  L_FROG=$'\xf0\x9f\x90\xb8 '
fi

# The default one-line prompt gets long.  Set a two-line prompt.
#
# \e]2;...\a    set the window title in xterm
# \e[1;7m       bold, reverse
# \e[0m         normal
#
PS1="\[\e]2;${L_FROG}\h\a\]\[\e[1;7m\] \h:\w \[\e[0m\]\n\\$ "

unset L_FROG
EOF
RUN mkdir ~/lilypond-build

###########################################################################
# lilypond: for running LilyPond
###########################################################################
FROM lilypond-base AS lilypond

# Include LilyPond in the PATH.  We don't do this in the base image
# because we don't want the development workflow to come to depend on
# it accidentally.
RUN echo 'PATH="$HOME/lilypond-build/out/bin:$PATH"' >> ~/.profile

## LilyPond itself requires nothing more, but you may wish to install
## extra packages that your personal workflow requires.  Adding them
## here will add them to the lilypond image without adding them to the
## lilypond-dev image.  Example:

# USER root
# RUN apt-get update \
# && DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y \
#     make \
# && rm -rf /var/lib/apt/lists/*
# USER user

###########################################################################
# lilypond-dev: for LilyPond development
###########################################################################
FROM lilypond-base AS lilypond-dev

## YUCK: Testing, e.g. make test-baseline, uses git.
##
## Packages that are for debugging and profiling rather than building
## and testing:
##
##   * gdb
##   * less
##   * moreutils (ts, errno, etc.)
##   * strace
##
# USER root
RUN apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y \
    autoconf \
    autotools-dev \
    bison \
    dblatex \
    debhelper \
    extractpdfmark \
    flex \
    fontforge \
    fonts-dejavu \
    fonts-linuxlibertine \
    fonts-noto-cjk \
    fonts-urw-base35 \
    g++ \
    gcc \
    gdb \
    gettext \
    git \
    groff \
    guile-3.0-dev \
    help2man \
    imagemagick \
    less \
    libfl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libgmp3-dev \
    libgs-dev \
    libltdl-dev \
    libpango1.0-dev \
    lmodern \
    m4 \
    make \
    mftrace \
    moreutils \
    netpbm \
    pkg-config \
    quilt \
    rsync \
    strace \
    texi2html \
    texinfo \
    texlive-fonts-recommended \
    texlive-font-utils \
    texlive-lang-cyrillic \
    texlive-metapost \
    texlive-plain-generic \
    texlive-xetex \
    tidy \
    ttf-bitstream-vera \
    zip \
&& rm -rf /var/lib/apt/lists/*

# Perl modules for makelsr
RUN apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y \
    cpanminus \
    libanyevent-forkmanager-perl \
    libdbd-mysql-perl \
    libfile-which-perl \
    libipc-run3-perl \
    pandoc \
&& cpanm module MySQL::Dump::Parser::XS \
&& DEBIAN_FRONTEND=noninteractive apt-get remove -y cpanminus \
&& DEBIAN_FRONTEND=noninteractive apt-get autoremove -y \
&& rm -rf /var/lib/apt/lists/*

# Support sharing the build directory with Samba.  If you don't need
# this, you can reduce the image size slightly by commenting it out.
# You'll also need to modify docker-compose.yaml so that it does not
# try to start smbd.
# USER root
RUN apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y \
    samba \
&& rm -rf /var/lib/apt/lists/* \
&& echo "[lilypond-build]" >> /etc/samba/smb.conf \
&& echo "   path = /home/user/lilypond-build" >> /etc/samba/smb.conf \
&& echo "   read only = yes" >> /etc/samba/smb.conf \
&& echo "   guest ok = yes" >> /etc/samba/smb.conf \
&& echo "   force user = root" >> /etc/samba/smb.conf

RUN echo 'export EM_PKG_CONFIG_PATH="$(pkg-config --variable pc_path pkg-config)"' >> ~/.bashrc

# USER user
