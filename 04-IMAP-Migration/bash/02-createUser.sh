# Create user with password "1"
sudo useradd -m -s /bin/bash imapubuntumigration
echo "imapubuntumigration:1" | sudo chpasswd

# Create Maildir for Dovecot
sudo -u imapubuntumigration maildirmake.dovecot /home/imapubuntumigration/Maildir
sudo -u imapubuntumigration maildirmake.dovecot /home/imapubuntumigration/Maildir/.Sent
sudo -u imapubuntumigration maildirmake.dovecot /home/imapubuntumigration/Maildir/.Trash
sudo -u imapubuntumigration maildirmake.dovecot /home/imapubuntumigration/Maildir/.Drafts

# Fix permissions
sudo chown -R imapubuntumigration:imapubuntumigration /home/imapubuntumigration/Maildir

# Check the subject of each mail

sudo grep -iE "^(From|Subject):" /home/imapubuntumigration/Maildir/new/1765016070.Vfd00I6003cM753329.ubuntu
sudo grep -iE "^(From|Subject):" /home/imapubuntumigration/Maildir/new/1765016109.Vfd00I6003dM536124.ubuntu
sudo grep -iE "^(From|Subject):" /home/imapubuntumigration/Maildir/new/1765016267.Vfd00I6003eM293098.ubuntu
sudo grep -iE "^(From|Subject):" /home/imapubuntumigration/Maildir/new/1765016286.Vfd00I6003fM148437.ubuntu


