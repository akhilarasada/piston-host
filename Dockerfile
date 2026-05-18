FROM ghcr.io/engineer-man/piston
ENV PORT=2000
EXPOSE 2000
CMD ["/bin/sh", "-c", "echo '=== /piston_api contents ===' && ls -la /piston_api && echo '=== package.json ===' && cat /piston_api/package.json && echo '=== src/ contents ===' && ls -la /piston_api/src 2>/dev/null || echo 'no src folder' && sleep 3600"]
