# Stage 1: Build Stage
FROM ubuntu:22.04 AS build

# Install necessary build tools and dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    build-essential \
    pkg-config \
    libx11-dev \
    libxkbfile-dev \
    libsecret-1-dev \
    openjdk-17-jdk \
    golang-go \
    python3-setuptools \
    python3-pip \
    curl \
    gnupg && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y yarn && \
    node -v && \
    python --version && pip --version && \
    yarn -v && \
    git clone https://github.com/sandeepss2020/theiaOriginal.git theia && \
    cd theia && \
    yarn && \
    yarn add -W react react-dom && \
    yarn download:plugins && \
    yarn browser build && \
    apt-get remove --purge -y build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Stage 2: Runtime Stage
FROM ubuntu:22.04

# Install only the necessary runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    openjdk-17-jdk \
    golang-go \
    git \
    openssh-client \
    bash \
    curl \
    gnupg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js and Yarn in the runtime stage
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y yarn && \
    yarn -v

# Create a non-root user and group named "theia"
RUN groupadd -r theia && useradd -r -g theia -s /bin/sh -m -d /home/theia theia

# Ensure ownership and permissions for the theia user
RUN mkdir -p /home/theia/.yarn && \
    chown -R theia:theia /home/theia && \
    chmod -R 755 /home/theia

# Copy only the necessary files from the build stage
COPY --from=build /theia /home/theia/theia

# Set the correct working directory for the Theia application
WORKDIR /home/theia/theia

# Switch to the "theia" user
USER theia

# Expose port 3000 for the Theia application
EXPOSE 3000

# Start the Theia browser application
CMD ["yarn", "browser", "start", "--hostname", "0.0.0.0"]
