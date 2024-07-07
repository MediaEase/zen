# -- START HERE --
## Instance layout (base paths)
method.insert = cfg.basedir,  private|const|string, (cat,"/home/{{USERNAME}}/download-clients/rtorrent/")
method.insert = cfg.homedir,  private|const|string, (cat,"/home/{{USERNAME}}/")
method.insert = cfg.download, private|const|string, (cat,(cfg.basedir),"download/")
method.insert = cfg.logs,     private|const|string, (cat,(cfg.basedir),"log/")
method.insert = cfg.logfile,  private|const|string, (cat,(cfg.logs),"rtorrent-",(system.time),".log")
method.insert = cfg.session,  private|const|string, (cat,(cfg.basedir),".sessions/")
method.insert = cfg.config,   private|const|string, (cat,(cfg.homedir),".config/")
method.insert = cfg.watch,    private|const|string, (cat,(cfg.basedir),"watch/")


## Create instance directories
execute.throw = sh, -c, (cat,\
    "mkdir -p \"",(cfg.download),"\" ",\
    "\"",(cfg.logs),"\" ",\
    "\"",(cfg.session),"\" ",\
    "\"",(cfg.watch),"/load\" ",\
    "\"",(cfg.watch),"/start\" ")


## Listening port for incoming peer traffic (fixed; you can also randomize it)
network.port_range.set = {{PORT_RANGE}}
network.port_random.set = yes
network.tos.set = throughput

## Tracker-less torrent and UDP tracker support
## (conservative settings for 'private' trackers, change for 'public')
dht.mode.set = disable
protocol.pex.set = no

trackers.use_udp.set = yes


## Peer settings
throttle.global_down.max_rate.set = 0
throttle.global_up.max_rate.set = 0

throttle.max_uploads.set = 100
throttle.max_uploads.global.set = 250

throttle.min_peers.normal.set = 1
throttle.max_peers.normal.set = 100
throttle.min_peers.seed.set = -1
throttle.max_peers.seed.set = -1
trackers.numwant.set = 80

protocol.encryption.set = allow_incoming,try_outgoing,enable_retry


## Limits for file handle resources, this is optimized for
## an `ulimit` of 1024 (a common default). You MUST leave
## a ceiling of handles reserved for rTorrent's internal needs!
network.http.max_open.set = 250
network.max_open_files.set = 600
network.max_open_sockets.set = 300
network.receive_buffer.size.set = 0
network.send_buffer.size.set = 0


## Memory resource usage (increase if you have a large number of items loaded,
## and/or the available resources to spend)
pieces.memory.max.set = 5400M
network.xmlrpc.size_limit.set = 4M


## Basic operational settings (no need to change these)
session.path.set = (cat, (cfg.session))
#config.path.set = (cat, (cfg.config))
directory.default.set = (cat, (cfg.download))
log.execute = (cat, (cfg.logs), "execute.log")
#log.xmlrpc = (cat, (cfg.logs), "xmlrpc.log")
execute.nothrow = sh, -c, (cat, "echo >",\
    (session.path), "rtorrent.pid", " ",(system.pid))


## Other operational settings (check & adapt)
encoding.add = utf8
system.umask.set = 0027
system.cwd.set = (directory.default)
network.http.dns_cache_timeout.set = 25
schedule2 = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))
#pieces.hash.on_completion = no
#pieces.hash.on_completion.set = no
#view.sort_current = seeding, greater=d.ratio=
#keys.layout.set = qwerty
network.http.capath.set = "/etc/ssl/certs"
network.http.ssl_verify_peer.set = 0
network.http.ssl_verify_host.set = 0


## Some additional values and commands
method.insert = system.startup_time, value|const, (system.time)
method.insert = d.data_path, simple,\
    "if=(d.is_multi_file),\
        (cat, (d.directory), /),\
        (cat, (d.directory), /, (d.name))"
method.insert = d.session_file, simple, "cat=(session.path), (d.hash), .torrent"


## Watch directories (add more as you like, but use unique schedule names)
## Add torrent
schedule2 = watch_load, 11, 10, ((load.verbose, (cat, (cfg.watch), "load/*.torrent")))
## Add & download straight away
schedule2 = watch_start, 10, 10, ((load.start_verbose, (cat, (cfg.watch), "start/*.torrent")))

## Run the rTorrent process as a daemon in the background
## (and control via XMLRPC sockets)
#system.daemon.set = true
network.scgi.open_local = /var/run/USERNAME/.rtorrent.sock
#execute.nothrow = chmod,770,(cat,(cfg.config),rpc.socket)
schedule2 = chmod_scgi_socket, 0, 0, "execute2=chmod,\"g+w,o=\",/var/run/USERNAME/.rtorrent.sock"


## Logging:
##   Levels = critical error warn notice info debug
##   Groups = connection_* dht_* peer_* rpc_* storage_* thread_* tracker_* torrent_*
print = (cat, "Logging to ", (cfg.logfile))
log.open_file = "log", (cfg.logfile)
log.add_output = "error", "log"
log.add_output = "torrent_debug", "log"
log.add_output = "tracker_error", "log"

schedule2 = init_plugins, 10, 0, "execute2={sh,-c,/usr/bin/php /srv/rutorrent/php/initplugins.php USERNAME &}"

# -- END HERE --
