# git clone --branch main --recursive https://github.com/varnishcache-friends/libvmod-geoip2
# ./autogen.sh
# ./configure
# make
# make check
# make install
# git clone --branch master --recursive https://github.com/nigoroll/libvmod-dynamic
# ./bootstrap
# ./configure
# make
# make check
# make install



import std;
import dynamic;
import geoip2;

backend default none;
probe health_check {
        .request = "GET /health_check.php HTTP/1.1"
                   "Host: example.com"
                   "X-Probe: Varnish backend health check"
                   "Connection: close";
        .timeout = 2s;
        .interval = 5s;
        .window = 10;
        .threshold = 5;   
}

acl purge {
    "10.0.0.0/16";
}
sub vcl_init {
    new country = geoip2.geoip2("/var/lib/GeoIP/GeoLite2-Country.mmdb");
    new this = dynamic.director(
    port = "80",
    probe = health_check,
    whitelist = purge,
    ttl = 1m);
}

sub vcl_recv {
    set req.backend_hint = this.backend("backend");
  
    set req.http.X-Real-IP = client.ip;
    if (req.http.X-Forwarded-For) {
        set req.http.X-Real-IP = regsub(req.http.X-Forwarded-For, "[, ].*$", "");
    }
    set req.http.X-GeoIP-Country-Code = country.lookup(
        "country/iso_code",
        std.ip(req.http.X-Real-IP, "0.0.0.0")
    ); 
    set req.http.X-Backend-Country-Code = req.http.X-GeoIP-Country-Code;
    if (req.http.X-GeoIP-Country-Code ~ "JP|HK|CH|AR|RU|BR|KP|SG|PH") {
        return (synth(403, "Access restricted"));
    }
