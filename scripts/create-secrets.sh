 export pull_secret=$(cat /root/pull-secret.json  |jq -c .)
 jinja2 mno.yaml.j2 | oc apply -f -