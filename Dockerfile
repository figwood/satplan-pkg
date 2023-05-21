FROM alpine:3.14.1 as calpath_builder
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk update && apk add --no-cache make cmake g++ sqlite-dev
WORKDIR /app
COPY calpath /app/
RUN cd orbitTools/core && make 
RUN cd orbitTools/orbit && make 
RUN cd calPath && make 

FROM golang:1.15 AS server_builder
WORKDIR /server
COPY satplan-server/go.mod .
RUN GO111MODULE=on GOPROXY="https://goproxy.cn" go mod download
COPY satplan-server .
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -a -ldflags '-extldflags "-static"' -o server

FROM node:12.21.0-slim AS web_builder
WORKDIR /web
COPY satplan-web/package.json .
RUN yarn install
COPY satplan-web .
RUN yarn run build

FROM nginx:1.17.0-alpine
WORKDIR /app
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk update && apk add --no-cache libstdc++ sqlite-dev 
COPY --from=calpath_builder /app/calPath/calpath /app/calpath

COPY --from=web_builder /web/dist /usr/share/nginx/html
COPY --from=web_builder /web/nginx.conf /etc/nginx/nginx.conf
COPY --from=server_builder /server/server /app/server
COPY --from=0 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY data /app/data/
COPY entry.sh .
RUN chmod a+x /app/entry.sh

EXPOSE 80 8080
CMD ["/app/entry.sh"]
