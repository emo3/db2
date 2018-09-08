db2 Cookbook
============

This cookbook installs IBM DB2 Server version 10.5 at
/opt/IBM/db2/V10.5 path.
This cookbook creates a DB2 instance with three databases in it. The names of the databases are specific to the WebSphere BPM requirements.

This cookbook can be used with my FTPlogin cookbook to scp binaries required to copy. I am not including the binaries in this cookbook.
This uses either a local FTP or Web Server.  You must set that up.

The code also verifies the checksum of the files after copying to the node. The install will fail if the checksum fails.

Requirements
------------
Platforms:<br>
RHEL/Centos 7.5<br>
Ubuntu 16.04<br>

Attributes
----------
TBD

Usage
-----
Add to the node's run list in this order:<br>
Code: knife node run_list remove {node} {recipe}<br>
recipe[db2::default]<br>
recipe[db2::installfp]<br>
recipe[db2::instance]<br>
recipe[db2::createdb]<br>

recipe::default installs Db2 10.5<br>
recipe::installfp installs Db2 10.5.9 fixpack<br>
recipe::instance creates Db2 database instance<br>
recipe::createdb creates three Db2 databases required for WebSphere BPM<br>

Use the following command to create shadow linux passwords for accounts:<br>
openssl passwd -1 -salt $(openssl rand -base64 6) [password]<br>

License and Authors<br>
-------------------<br>
Heavily Modified By:<br>
Edward Overton, USA<br>
Profile: https://github.com/emo3<br>
Original:<br>
Rohit Gabriel, Auckland, New Zealand.<br>
Profile: https://nz.linkedin.com/in/rohit-gabriel-22a76320<br>
