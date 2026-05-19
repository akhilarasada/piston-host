FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=8080

# ── Base tools ────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y curl ca-certificates unzip gnupg && \
    rm -rf /var/lib/apt/lists/*

# ── Node.js 18 ────────────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# ── Python 3, Java, C/C++, Go, Ruby, Mono (C#), Rust ────────────────────────
RUN apt-get update && apt-get install -y \
    python3 \
    default-jdk \
    gcc g++ \
    golang-go \
    ruby \
    mono-complete \
    rustc cargo \
    && rm -rf /var/lib/apt/lists/*

# ── TypeScript (global) ───────────────────────────────────────────────────────
RUN npm install -g typescript

# ── Kotlin compiler ───────────────────────────────────────────────────────────
ENV KOTLIN_VERSION=1.8.20
RUN curl -L "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" \
    -o /tmp/kotlin.zip && \
    unzip /tmp/kotlin.zip -d /opt/ && \
    rm /tmp/kotlin.zip
ENV PATH="/opt/kotlinc/bin:${PATH}"

# ── App ───────────────────────────────────────────────────────────────────────
WORKDIR /app
COPY package.json .
RUN npm install --production
COPY server.js .

EXPOSE 8080
CMD ["node", "server.js"]
