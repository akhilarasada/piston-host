FROM ghcr.io/engineer-man/piston
ENV PORT=2000

# Copy start script then strip Windows CRLF -> LF so it runs on Linux
COPY start.sh /start.sh.raw
RUN tr -d '\r' < /start.sh.raw > /start.sh && chmod +x /start.sh

EXPOSE 2000
CMD ["/bin/sh", "/start.sh"]
