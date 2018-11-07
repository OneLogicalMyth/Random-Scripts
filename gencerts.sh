echo "creating public key"
openssl pkcs12 -in $1 -clcerts -nokeys -out $2.cer
echo "creating private key"
openssl pkcs12 -in $1 -nocerts -nodes  -out $2.key
echo "creating ca key"
openssl pkcs12 -in $1 -out $2.crt -nodes -nokeys -cacerts
