# Use RHEL UBI 8.5 as base image
FROM registry.access.redhat.com/ubi8:8.5

# Install httpd
RUN dnf install -y httpd --nodocs --setopt install_weak_deps=False && \
    dnf clean all -y

# Copy the website
COPY files/* /var/www/html/

# Configure httpd to run as non-root
RUN sed -i -e 's/root/1001/g' /usr/lib/tmpfiles.d/httpd.conf && \
    sed -i -e 's/apache/1001/g' /usr/lib/tmpfiles.d/httpd.conf && \
    chown -R 1001 /var/log/httpd && \
    chmod u+s /usr/sbin/httpd

# Expose port 80/tcp
EXPOSE 80

# Switch to User 1001
USER 1001

# Start httpd
CMD ["httpd", "-DFOREGROUND"]
