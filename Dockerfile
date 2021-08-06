FROM debian

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libreoffice \
        fonts-noto-cjk-extra fonts-liberation2 \
        imagemagick \
        poppler-utils \
        xpdf \
        curl \
        ca-certificates \
        ruby-full \
        && \ 
    apt-get -y --purge autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN gem install sinatra

RUN mkdir -p /app
WORKDIR /app

ADD lib/ /app/lib
ADD views /app/views
ADD main.rb /app/main.rb
ADD resources/template.vci /app/resources/template.vci
ADD resources/policy.xml /etc/ImageMagick-6/policy.xml

ENV PORT=5000
CMD ruby main.rb -p $PORT -o '0.0.0.0'
