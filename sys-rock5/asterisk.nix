{ config, lib, pkgs, ...}:
{
	services.asterisk = {
		enable = true;
		confFiles = {
			"extensions.conf" = ''
			[from-internal]
			exten = 100,1,Answer()
			same = n,Wait(1)
			same = n,Playback(hello-world)
			same = n,Hangup()
			'';

			"pjsip.conf" = ''
			[transport-udp]
			type=transport
			protocol=udp
			bind=0.0.0.0

			[1234]
			type=endpoint
			context=from-internal
			disallow=all
			allow=ulaw
			auth=1234
			aors=1234

			[1234]
			type=auth
			auth_type=userpass
			password=fritz
			username=1234

			[1234]
			type=aor
			max_contacts=1
			'';
		};
	};
}
