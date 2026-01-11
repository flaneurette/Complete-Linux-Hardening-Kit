# Server-Scripts 
Collection of useful server bash scripts

Upload to linux server:

`/root/`
or:
`/usr/local/bin/`

### Usage

`chmod +x script.sh`

Run it:

`sudo ./script.sh`


### .my.cnf

Edit `.my.cnf` and copy to `/root/` or `user folder`. Required if you want MySQL to read credentials for making backups. (safer)


### Cron

Some scripts, or most, can be added to cron.

`sudo crontab -e`

And add a new line to the script.

Example:
```
# m h  dom mon dow   command
0 2 * * * /usr/local/bin/backup.sh
```
