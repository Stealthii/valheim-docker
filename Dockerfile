# ------------------ #
# -- Odin Builder -- #
# ------------------ #
FROM stealthii/valheim-odin:latest as RustBuilder

# --------------- #
# -- Steam CMD -- #
# --------------- #
FROM cm2network/steamcmd:root

RUN apt-get update          \
    && apt-get install -y   \
    htop net-tools nano     \
    netcat curl wget        \
    cron sudo gosu dos2unix \
    && gosu nobody true     \
    && dos2unix

# Set up timezone information
ENV TZ=America/Los_Angeles

# Copy hello-cron file to the cron.d directory
COPY --chown=steam:steam  src/cron/auto-update /etc/cron.d/auto-update

# Apply cron job
RUN crontab /etc/cron.d/auto-update

# Server Specific env variables.
ENV PORT "2456"
ENV NAME "Valheim Docker"
ENV WORLD "Dedicated"
ENV PUBLIC "1"
ENV PASSWORD "12345"
ENV AUTO_UPDATE "0"

COPY ./src/scripts/*.sh /home/steam/scripts/
COPY ./src/scripts/entrypoint.sh /entrypoint.sh
COPY --from=RustBuilder /data/odin/target/release /home/steam/.odin

#WORKDIR /home/steam/valheim

ENV PUID=1000
ENV PGID=1000
RUN usermod -u ${PUID} steam \
    && groupmod -g ${PGID} steam \
    && chsh -s /bin/bash steam

ENTRYPOINT ["/bin/bash","/entrypoint.sh"]
CMD ["/bin/bash", "/home/steam/scripts/start_valheim.sh"]
