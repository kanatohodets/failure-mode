#Failure Mode

Failure Mode is an API for burn-testing Dockerized web applications.

It manages a collection of containers and subjects them to horrible things
like:

* latency (consistent or with random fluctuation)
* rejected packets
* dropped packets
* bandwidth throttling *
* CPU/memory starvation/oversubscription *
* other calamities yet to be invented *

(* not yet implemented)

These tools let you test a web application/supporting infrastructure for
robustness in the face of external failures. This is a bit like a cross between NetFlix's 
Simian Army and repeatable, deliberate DevOps practices like 
[Failure Friday](http://blog.pagerduty.com/2013/11/failure-friday-at-pagerduty/).

This is an early draft: there are a great number of sharp edges and unfortunate API
design choices that may or may not be fixed up/totally broken as time goes on.

One goal is to pair this 'agent' with a frontend app for creating, managing,
running, and monitoring collections of 'disaster' test cases for web app
deployments for usage as part of a CI process.

However, I'd love to hear from you if you have ideas on how this sort of thing
could be useful for your needs: feel free to open issues for suggestions or comments.

##API
### Containers
Note: any `<container id>` may be shortened to anything unambiguous, just like
when using the docker client.

See running containers:

    GET /containers

See `docker inspect` for a given container:

    GET /containers/<container id>

### Conditions
See the list of currently-applied conditions for a given container:

    GET /containers/<container id>/conditions
    curl localhost:3005/containers/2c905/conditions | json_pp
    {
       "conditions" : [
          {
             "container_condition_id" : 114,
             "container_id" : "dcc34db909a2eb5633b4d2909b6f6170efd926e58008f66ec6db1eef66248d12",
             "condition_id" : 0,
             "condition_type" : 104
          },
          {
             "condition_type" : 100,
             "condition_id" : 65,
             "container_condition_id" : 115,
             "container_id" : "dcc34db909a2eb5633b4d2909b6f6170efd926e58008f66ec6db1eef66248d12"
          }
       ]
    }

Add a new condition to a container:

    POST /containers/<container id>/conditions/<type>/<subtype>
    curl -H "Content-Type: application/json" -X POST -d '{"args": {"base": "500"}}' http://localhost:3005/containers/2c905/condition/net/delay
    {"message":"OK"}

Remove a condition:

    DELETE /containers/<container id>/conditions/<type>/<subtype>
    curl -X DELETE http://localhost:3005/containers/2c905/conditions/net/delay
    {"message":"OK"}

Remove all conditions:

    DELETE /containers/<container id>/conditions
    curl -X DELETE http://localhost:3005/containers/2c905/conditions
    {"message":"OK"}

###Conditions

####Net
#####Delay
Add latency to all network traffic leaving this host.

    base: 400 # base latency in ms
    deviation: 50 # standard deviation, in ms
    correlation: 10 # percent: probability that that one packet being delayed will lead to the next packet being delayed
    distribution:  uniform | normal | pareto |  paretonormal
    # man netem(8) for more detailed information

#####Drop
Drop packets from all hosts with a given probability (packet loss rate).

    base: 40 # packet loss percentage
    correlation # percent

#####Ignore
Ignore (drop) all packets from a given host (without notifying said host).

    target: 172.0.2.4 # ip address or domain of host

#####Reject
Reject all packets from a given host (and respond with `port-unreachable` to said host).

    target: 172.0.2.4 # ip address or domain of host

##Installation & Running

The (Linux) host will need `make`, `docker`, a recent `perl` (preferably 5.18 or
newer, earlier versions untested), and Mojolicious (tested with 5.x). Also
`iptables` and `tc`. This may shift towards running inside its own docker
container in the future.

On the host where you plan to conduct the burn testing:

1. install docker
2. install mojolicious: `curl get.mojolicio.us | sh` or `cpanm Mojolicious` -- libmojolicious in ubuntu is way old!
3. clone failure mode: `git clone github.com/kanatohodets/failure-mode`
4. run failure mode as root using hypnotoad. by default it runs on 3005: `sudo hypnotoad scripts/agent`

##### about running as root
This is one of the sharp edges mentioned earlier. Failure Mode needs to be able
to run the docker client and manipulate iptables/queueing disciplines in order
towork its magic. These things generally require root access.

So, er, don't put this on a public facing host. Right?

##Technologies

* Perl/Mojolicious
* netem/tc/iptables
* SQLite
* Docker

## License

Artistic License 2.0
