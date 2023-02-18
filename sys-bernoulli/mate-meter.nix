{ pkgs, ... } : 
{
  systemd.timers."mate-meter" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "2h";
        Unit = "mate-meter.service";
      };
  };

  systemd.services."mate-meter" = {
    script = ''
      ${pkgs.curl}/bin/curl 'https://cdn5.editmysite.com/app/store/api/v18/editor/users/139049822/sites/982743195728728276/products?page=1&per_page=50&sort_by=popularity_score&visibilities\[\]=visible&include=images,category,media_files' \
  -H 'authority: cdn5.editmysite.com' \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8' \
  -H 'cache-control: no-cache' \
  -H 'origin: https://www.club-mate.uk' \
  -H 'pragma: no-cache' \
  -H 'referer: https://www.club-mate.uk/' \
  -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="101", "Google Chrome";v="101"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Linux"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: cross-site' \
  -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.0.0 Safari/537.36' \
  --compressed | ${pkgs.jq}/bin/jq -r '.data | .[] | "\(.name) \(.inventory.total)"' | ${pkgs.gnused}/bin/sed 's/$/<br>/g' > /home/stary/www/mate-meter/index.html
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "stary";
    };
  };
}
