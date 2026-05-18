FROM ghcr.io/engineer-man/piston
ENV PORT=2000
EXPOSE 2000
CMD ["/bin/sh", "-c", "echo '=== ROOT ===' && ls -la / && echo '=== FIND package.json ===' && find / -name 'package.json' 2>/dev/null | grep -v node_modules && echo '=== FIND js files ===' && find / -name '*.js' 2>/dev/null | grep -v node_modules | head -20 && echo '=== DONE ===' && sleep 3600"]
