# Default MongoDB version is 6.0 (overridden by build args)
ARG MONGO_VERSION=6.0

FROM amazon/aws-cli:2.11.3 AS awscli

FROM mongo:${MONGO_VERSION}
LABEL maintainer="Omid Rouhani <o.rohani@gmail.com>"

COPY --from=awscli /usr/local/bin/aws /usr/local/bin/aws

COPY run.sh /usr/local/bin/run.sh
COPY env.sh /env.sh

RUN chmod +x /usr/local/bin/run.sh

ENV PATH="/usr/local/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/run.sh"]
