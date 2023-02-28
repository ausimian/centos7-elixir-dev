FROM centos:centos7 AS builder

RUN  yum -y update
RUN  yum -y group install "Development Tools"
RUN  yum -y install wget zlib-devel pcre-devel perl-core ncurses-devel

WORKDIR /src
RUN  wget --quiet https://ftp.openssl.org/source/openssl-3.0.8.tar.gz && \
     tar xzf openssl-3.0.8.tar.gz && \
     cd openssl-3.0.8 && \
     ./config no-shared no-module && \
     make -j && \
     make install_sw && \
     cd /src && \
     rm -fr openssl-3.0.8

RUN  yum -y install centos-release-scl scl-utils-build
RUN  yum -y install devtoolset-9 devtoolset-9-gcc-c++ devtoolset-9-libgccjit

WORKDIR /src
RUN  wget --quiet https://github.com/erlang/otp/releases/download/OTP-25.2.2/otp_src_25.2.2.tar.gz && \
     tar xzf otp_src_25.2.2.tar.gz
RUN  cd otp_src_25.2.2 && \
     . /opt/rh/devtoolset-9/enable && \
     ./configure --prefix=/usr/local \
                 --enable-jit \
                 --with-ssl   \
                 --disable-dynamic-ssl-lib \
                 --without-javac \
                 --without-megaco \
                 --without-odbc && \
     make -j && \
     make DESTDIR=/tmp/otp install


FROM centos:centos7
RUN  yum -y update
RUN  yum -y install zlib terminfo wget unzip
COPY --from=builder /tmp/otp/usr/local /usr/local
RUN  cd /usr/local && \
     wget --quiet https://github.com/elixir-lang/elixir/releases/download/v1.14.3/elixir-otp-25.zip && \
     unzip elixir-otp-25.zip && \
     rm -f elixir-otp-25.zip
RUN  localedef -c -f UTF-8 -i en_US en_US.UTF-8
ENV  LC_ALL=en_US.UTF-8

RUN  mix local.hex --force
RUN  mix local.rebar --force
