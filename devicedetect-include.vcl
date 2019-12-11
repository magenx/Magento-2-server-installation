include "devicedetect.vcl";
sub vcl_recv {
    call devicedetect;
}
# req.http.X-UA-Device is copied by Varnish into bereq.http.X-UA-Device

# so, this is a bit conterintuitive. The backend creates content based on the normalized User-Agent,
# but we use Vary on X-UA-Device so Varnish will use the same cached object for all U-As that map to
# the same X-UA-Device.
# If the backend does not mention in Vary that it has crafted special
# content based on the User-Agent (==X-UA-Device), add it.
# If your backend does set Vary: User-Agent, you may have to remove that here.
sub vcl_backend_response {
    if (bereq.http.X-UA-Device) {
        if (!beresp.http.Vary) { # no Vary at all
            set beresp.http.Vary = "X-UA-Device";
        } elsif (beresp.http.Vary !~ "X-UA-Device") { # add to existing Vary
            set beresp.http.Vary = beresp.http.Vary + ", X-UA-Device";
        }
    }
    # comment this out if you don't want the client to know your classification
    set beresp.http.X-UA-Device = bereq.http.X-UA-Device;
}

# to keep any caches in the wild from serving wrong content to client #2 behind them, we need to
# transform the Vary on the way out.
sub vcl_deliver {
    if ((req.http.X-UA-Device) && (resp.http.Vary)) {
        set resp.http.Vary = regsub(resp.http.Vary, "X-UA-Device", "User-Agent");
    }
}
