FROM louislam/uptime-kuma:base-debian AS build
WORKDIR /app

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
ENV UPTIME_KUMA_BASE_PATH=/uptime-kuma/
ENV BASE_PATH=/uptime-kuma/

COPY .npmrc .npmrc
COPY package*.json ./
RUN npm install
RUN rm -f .npmrc

COPY . .
RUN npm run build

RUN npm ci --production && \
    chmod +x /app/extra/entrypoint.sh


FROM louislam/uptime-kuma:base-debian AS release
WORKDIR /app

ENV UPTIME_KUMA_BASE_PATH=/uptime-kuma/
ENV BASE_PATH=/uptime-kuma/

# Copy app files from build layer
COPY --from=build /app /app

EXPOSE 3001
VOLUME ["/app/data"]
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD node extra/healthcheck.js
ENTRYPOINT ["/usr/bin/dumb-init", "--", "extra/entrypoint.sh"]
CMD ["node", "server/server.js"]