{ lib, ... } : 
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "bernoulli.9net.org" = { enableACME = true; forceSSL = true; };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "me@chloe-is.online";
    };

    certs = {
    };
  };
}