FROM ghcr.io/engineer-man/piston

# Piston requires /piston directory for packages and job storage
RUN mkdir -p /piston

# Strip Windows CRLF from start.sh
COPY start.sh /start.sh.raw
RUN tr -d '\r' < /start.sh.raw > /start.sh && chmod +x /start.sh

EXPOSE 8080
CMD ["/bin/sh", "/start.sh"]
