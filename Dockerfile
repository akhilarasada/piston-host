FROM ghcr.io/engineer-man/piston
ENV PORT=2000
COPY start.sh /start.sh
RUN chmod +x /start.sh
EXPOSE 2000
CMD ["/bin/sh", "/start.sh"]
