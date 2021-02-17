FROM koduki/vci-gen-sinatra

RUN mkdir -p /app
WORKDIR /app

ADD lib /app/lib
ADD views /app/views
ADD public /app/public
ADD main.rb /app/main.rb
ADD resources/template.vci /app/template.vci
ADD resources/policy.xml /etc/ImageMagick-6/policy.xml

ENV PORT=5000
CMD ruby main.rb -p $PORT -o '0.0.0.0'
