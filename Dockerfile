FROM eceasy/cli-proxy-api:latest

USER root

COPY start.sh /usr/local/bin/cpa-start
RUN chmod 0755 /usr/local/bin/cpa-start

EXPOSE 8317

ENTRYPOINT ["/usr/local/bin/cpa-start"]
