import requests

api_key = ''
api_email = 'email@gmail.com'
api_zone = ''
api_dns = ''
sub_domain = 'sub.domain.example'

# get the current external IP
extip = requests.get('https://api.ipify.org/')
extip = extip.content
print('[*] Your external IP is ' + extip)

# set the current IP
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
