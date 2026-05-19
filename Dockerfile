FROM ghcr.io/engineer-man/piston
ENV PORT=2000

# Piston requires /piston directory for packages and job storage
RUN mkdir -p /piston

# Strip Windows CRLF from start.sh
COPY start.sh /start.sh.raw
RUN tr -d '\r' < /start.sh.raw > /start.sh && chmod +x /start.sh

EXPOSE 2000
CMD ["/bin/sh", "/start.sh"]
