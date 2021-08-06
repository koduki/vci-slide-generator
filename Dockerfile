FROM ruby

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        poppler-utils \
        && \ 
    apt-get -y --purge autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN gem install sinatra puma

RUN mkdir -p /app

WORKDIR /app

ADD lib/ /app/lib
ADD views /app/views
ADD main.rb /app/main.rb
ADD resources/template.vci /app/resources/
ADD resources/vci-main.lua.erb /app/resources/
ADD resources/policy.xml /etc/ImageMagick-6/policy.xml
ENV PORT=5000
CMD ruby main.rb -p $PORT -o '0.0.0.0'
