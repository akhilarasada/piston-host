FROM ghcr.io/engineer-man/piston

# Force Piston to always use port 2000 regardless of Railway's PORT variable
ENV PORT=2000

COPY start.sh /start.sh
RUN chmod +x /start.sh
EXPOSE 2000
CMD ["/start.sh"]
