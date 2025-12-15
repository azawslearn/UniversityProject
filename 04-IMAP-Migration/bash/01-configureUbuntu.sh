#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------------------------
# This script installs and configures a complete local mail server on Ubuntu
# using Postfix for SMTP and Dovecot for IMAP/POP3.
#
# What the script does:
#   1. Updates the system packages.
#   2. Installs Postfix, Dovecot, and mail utilities.
#   3. Sets the system mailname to the chosen domain.
#   4. Configures Postfix with the specified hostname, domain, Maildir delivery,
#      and address rewriting rules to ensure all outbound mail uses the domain.
#   5. Generates and maps /etc/postfix/generic for address rewriting.
#   6. Configures Dovecot to use Maildir format.
#   7. Creates a Maildir directory for the actual user running the script.
#   8. Restarts Postfix and Dovecot to apply configuration.
#   9. Prints a summary of the final mail server configuration.
#
# The result is a functioning local mail server delivering mail to Maildir
# for the system user, with outbound messages rewritten to the configured domain.
# ------------------------------------------------------------------------------

# ==============================
# Variables
# ==============================
MYDOMAIN="sofiauniversity.dnsabr.com"
MYHOSTNAME="sofiauniversity.dnsabr.com"

# Detect the actual login user, even if run via sudo
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
MAILDIR="$TARGET_HOME/Maildir"

SHORT_HOST="$(hostname -s || true)"
FQDN_HOST="$(hostname -f || true)"

# ==============================
# 1. Update system
# ==============================
echo "Updating system..."
apt update
apt -y upgrade
apt -y autoremove

# ==============================
# 2. Install packages
# ==============================
echo "Installing Postfix, Dovecot, and mail utilities..."
DEBIAN_FRONTEND=noninteractive apt install -y postfix dovecot-imapd dovecot-pop3d mailutils

# ==============================
# 3. Configure system mailname
# ==============================
echo "$MYDOMAIN" > /etc/mailname

# ==============================
# 4. Configure Postfix
# ==============================
echo "Configuring Postfix..."
postconf -e "myhostname = $MYHOSTNAME"
postconf -e "mydomain = $MYDOMAIN"
postconf -e "myorigin = /etc/mailname"

postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain, $(hostname)"

postconf -e "relay_domains ="
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = all"
postconf -e "home_mailbox = Maildir/"
postconf -e "smtp_generic_maps = hash:/etc/postfix/generic"
postconf -e "local_transport = local"

# ==============================
# 5. Setup address rewriting
# ==============================
echo "Setting up address rewrite..."
cat > /etc/postfix/generic <<EOF
$TARGET_USER@$SHORT_HOST        $TARGET_USER@$MYDOMAIN
@$SHORT_HOST                    @$MYDOMAIN
$TARGET_USER@$FQDN_HOST        $TARGET_USER@$MYDOMAIN
@$FQDN_HOST                    @$MYDOMAIN
$TARGET_USER@localhost         $TARGET_USER@$MYDOMAIN
@localhost                     @$MYDOMAIN
EOF

postmap /etc/postfix/generic

# ==============================
# 6. Configure Dovecot
# ==============================
echo "Configuring Dovecot..."
sed -i 's|^#\?mail_location =.*|mail_location = maildir:~/Maildir|' /etc/dovecot/conf.d/10-mail.conf

# ==============================
# 7. Setup Maildir for actual user
# ==============================
echo "Creating Maildir for $TARGET_USER at $MAILDIR..."
install -d -m 700 "$MAILDIR"/{cur,new,tmp}
chown -R "$TARGET_USER:$TARGET_USER" "$MAILDIR"

# ==============================
# 8. Restart services
# ==============================
echo "Restarting Postfix and Dovecot..."
systemctl restart postfix
systemctl restart dovecot

# ==============================
# 9. Show configuration summary
# ==============================
echo "--------------------------------------"
echo "Mail server installed and configured."
echo "Domain: $MYDOMAIN"
echo "Hostname: $MYHOSTNAME"
echo "Local mailbox: $MAILDIR"
echo "--------------------------------------"
postconf | egrep 'myhostname|mydomain|myorigin|mydestination|relay_domains|home_mailbox'
echo "--------------------------------------"