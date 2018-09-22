import requests, json

# CloudFlare Config
api_key = '-----'
api_email = '-----'
api_zone = '-----'
api_dns = '-----'
sub_domain = '-----'

# DigitalOcean Config
FWID = '-----'
FWDroplets = ['-----','-----','-----']
FWName = '-----'
APIKey = '-----'

# get the current external IP
extip = requests.get('https://api.ipify.org/')
extip = extip.content
print('[*] Your external IP is ' + extip + '.')

# grab IPv4 list from cloudflare
response = requests.get('https://www.cloudflare.com/ips-v4')
if response.status_code == requests.codes.ok:
    list = response.content
    CFlist = [s.strip() for s in list.splitlines()]
    print('[+] Obtained an updated list of CloudFlare IPv4 ranges.')
else:
    print('[-] Failed to obtain CloudFlare IPv4 ranges.')
    raise SystemExit(0)

# DigitalOcean FW data
FWData = {
            "name": FWName,
            "droplet_ids": FWDroplets,
            "inbound_rules": [
                {
                    "ports": "22",
                    "protocol": "tcp",
                    "sources": {
                        "addresses": [ extip ]
                    }
                },
                {
                    "ports": "80",
                    "protocol": "tcp",
                    "sources": {
                        "addresses": CFlist
                    }
                },
                {
                    "ports": "443",
                    "protocol": "tcp",
                    "sources": {
                        "addresses": CFlist
                    }
                }
            ],
            "tags": []
        }


# set the current IP on DigitalOcean
url = 'https://api.digitalocean.com/v2/firewalls/' + FWID
head =  {
            'Authorization'   : 'Bearer ' + APIKey,
            'Content-Type' : 'application/json'
        }
response = requests.put(url, json=FWData, headers=head)
if response.status_code == requests.codes.ok:
    print('[+] External IP and CloudFlare IPv4 list updated on DigitalOcean.')
else:
    print('[-] Failed to update external IP and CloudFlare IPv4 list on DigitalOcean.')
    raise SystemExit(0)

# set the current IP on CloudFlare
url = 'https://api.cloudflare.com/client/v4/zones/' + api_zone + '/dns_records/' + api_dns
data =  {
            'type'    : 'A',
            'name'    : sub_domain,
            'content' : extip,
            'ttl'     : 120,
            'proxied' : False
        }
head =  {
            'X-Auth-Email' : api_email,
            'X-Auth-Key'   : api_key,
            'Content-Type' : 'application/json'
        }
response = requests.put(url, json=data, headers=head)

if response.status_code == requests.codes.ok:
    print('[+] External IP updated on Cloudflare.')
else:
    print('[-] Failed to update external IP on Cloudflare.')
