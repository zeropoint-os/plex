FROM plexinc/pms-docker:latest

# Expose the default Plex port
EXPOSE 32400

# Use upstream image's startup; this file is present so local builds can be created if desired
CMD ["/init"]
