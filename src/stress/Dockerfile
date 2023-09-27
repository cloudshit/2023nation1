FROM alpine

RUN apk add --no-cache libc6-compat 
RUN apk add --no-cache curl
RUN apk add --no-cache stress-ng
RUN adduser --disabled-password app

RUN mkdir /app
WORKDIR /app

COPY ./main /app/app
RUN chmod a+rx /app/app

USER app

CMD ["./app"]
