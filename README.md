

Developer Setup
---------------
The following steps should get a new developer up and running.  Feel free to further create shortcuts and update this documentation


1.  Download and install mongo:  http://www.mongodb.org/downloads.  I have a soft link to mongo and mongod

2.  Install node

3.  Navigate to the root of the project and type `npm install`

4.  Copy config/example.config to dev.config and edit the settings.  If you need a mail server I can give you our credentials for sendgrid.

5.  On the root of the project:  `chmod +x bin`

6.  The following steps will need to be followed everytime you run the project:

7.  Open a terminal and run mongod

8.  Open another terminal, navigate to the project root and type `bin/watch-js`

9.  Open another terminal, navigate to the project root and type `coffee start.coffee`


### NOTES:

- create an user

- set user password: curl -d "user[email]=user@host.edu&user[password]=secret" http://localhost:3000/api/users/user@host.edu

