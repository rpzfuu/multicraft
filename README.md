# Multicraft Fast Install for Ubuntu 16.04

This guide provides a quick and easy method to install Multicraft on Ubuntu 16.04. Follow the instructions below to get started.

## Prerequisites

- Ubuntu 16.04 server
- Root or sudo access

## Installation Steps

1. **Run the Installation Command**

   Open a terminal and run the following command to download and execute the installation script:

   ```sh
   curl https://raw.githubusercontent.com/rpzfuu/multicraft/master/multicraftserver.sh > multicraftserver.sh && bash ./multicraftserver.sh
   ```

2. **Follow the On-Screen Prompts**

   The script will prompt you for the following information:

   - SYSADMIN email address
   - Fully Qualified Domain Name (FQDN) of the server
   - Daemon number (if this is the only instance, type '1')
   - Minecraft key (if available, otherwise type 'no')
   - A complex 8-character password

3. **Complete the Installation**

   The script will automatically install and configure the necessary packages, including Apache, MySQL, and PHP. It will also set up Multicraft and secure your MySQL installation.

## Post-Installation

After the script completes, you will see the following message:

```
Go to the web panel: http://your.address/multicraft/install.php
STOP! Copy and don't lose the following passwords:
multicraft_panel: multicraft_panel / your_panel_password
multicraft_daemon: multicraft_daemon / your_daemon_password
```

Visit the provided URL to finalize the Multicraft installation through the web interface. Remember to save the displayed passwords for future reference.

## Additional Resources

For a visual walkthrough, watch the following video:

[Multicraft Installation Walkthrough](https://youtu.be/ohv8QXDd8Do)

By following these steps, you should have Multicraft up and running on your Ubuntu 16.04 server. If you encounter any issues, refer to the video or consult the official Multicraft documentation.
