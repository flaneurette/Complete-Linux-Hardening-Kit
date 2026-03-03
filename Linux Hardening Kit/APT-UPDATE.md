# Apt Update

This warrants a special readme. Most updates pulled by `apt update` uses `http port 80`, instead of `https port 443`.
Everyone could eavesdrop on what you pull in, and what version you're updating.
Kinda dated practice. Let's fix it.

# Fix

```
sudo apt install apt-transport-https
```

Then edit:

```
sudo nano /etc/apt/sources.list.d/ubuntu.sources
```

And replace all `http` with `https`

Done. 