#!/bin/bash

api()
{

  if [[ $HTTP_OP = "POST" || $HTTP_OP = "PATCH" ]]; then
     curl --http1.1 -s -X ${HTTP_OP} ${API_URL}${THE_PATH} \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/vnd.api+json" \
                -H "prefer: profile=$PROFILE" \
	              --data "@/var/tmp/$0.$$.json"
  else
         curl --http1.1 -s -X ${HTTP_OP} ${API_URL}${THE_PATH} \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/vnd.api+json" \
                    -H "prefer: profile=$PROFILE"
  fi

}

commands()
{
cat << !
account                get     GET /account/details
access-policy          get     GET /access-policies/{access-policy}
access-policies        list    GET /access-policies
apply                  get     GET /applies/{apply}
configuration-version  get     GET /configuration-versions/{configuration_version}
ingress-attributes     get     GET /configuration-versions/{configuration_version}/ingress-attributes
configuration-versions list    GET /configuration-versions?filter[workspace]={workspace}
configuration-versions create  POST /configuration-versions
cost-estimate          get     GET /cost-estimates/{cost_estimate}
cost-estimates         get-log GET /cost-estimates/{cost_estimate}/output
environment            create  POST /enviroments
environment            delete  DELETE /enviroments/{environment}
environment            get     GET /enviroments/{environment}
environment            update  PATCH /enviroments/{environment}
environments           list    GET /enviroments?filter[account]={account}
idps                   list    GET /identity-providers
idp                    get     GET /identity-providers/{id}
organizations          list    GET /organizations
organization           get     GET /organizations/{organization}
module                 create  POST /organizations/{organization}/registry-modules
module                 publish POST /registry-modules
module                 delete  POST /registry-modules/actions/delete/{organization}/{module_name}
module-provider        delete  POST /registry-modules/actions/delete/{organization}/{module_name}/{provider_name}
module-version         delete  POST /registry-modules/actions/delete/{organization}/{module_name}/{provider_name}/{version}
module                 get     GET /registry-modules/{module}
module                 get-np  GET /registry-modules/{organization}/{module_name}/{module_provider}
module                 resync  POST /registry-modules/{organization}/{module_name}/{module_provider}/resync
module                 create-version POST /registry-modules/{organization}/{module_name}/{module_provider}/versions
module                 resync-version POST /registry-modules/{organization}/{module_name}/{module_provider}/{version}/resync
workspaces             list    GET /organizations/{organization}/workspaces
workspace              create  POST /organizations/{organization}/workspaces
org-workspace          delete  DELETE /organizations/{organization}/workspaces/{workspace_name}
org-workspace          get     GET /organizations/{organization}/workspaces/{workspace_name}
org-workspace          update  PATCH /organizations/{organization}/workspaces/{workspace_name}
workspace              delete  DELETE /workspaces/{workspace}
workspace              get     GET /workspaces/{workspace}
workspace              update  PATCH /workspaces/{workspace}
workspace              lock    POST /workspaces/{workspace}/actions/lock
workspace              unlock  POST /workspaces/{workspace}/actions/unlock
plan                   get     GET /plans/{plan}
policy-check           get     GET /policy-checks/{policy-check}
policy-check           override POST /policy-checks/{policy_check}/actions/override
policy-check           get-log GET /policy-checks/{policy_check}/actions/output
policy-checks          list    GET /runs/{run}/policy-checks
run                    create  POST /runs
run                    get     GET /runs/{run}
run                    apply   POST /runs/{run}/actions/apply
run                    cancel  POST /runs/{run}/actions/cancel
run                    discard POST /runs/{run}/actions/discard
run                    force-cancel POST /runs/{run}/actions/force-cancel
run                    policy-input POST /runs/{run}/policy-input
runs                   list    GET /runs?filter[workspace]={workspace}
state-versions         list    GET /state-versions
state-version          get     GET /state-versions/{state_version}
state-version          get-current GET /workspaces/{workspace}/current-state-version
state-version          create  POST /workspaces/{workspace}/state-versions
users                  list    GET /users
user                   get     GET /users/{id}
vars                   list    GET /vars
var                    create  POST /vars
var                    delete  DELETE /vars/{var}
var                    get     GET /vars/{var}
var                    update  PATCH /vars/{var}
!
}

aliases ()
{
  cat << !
acc  account
accs accounts
app apply
cfv  configuration-version
cfvs configuration-versions
cse cost_estimate
cses cost_estimates
org organization
orgs organizations
mod module
mods modules
ws workspace
wss workspaces
ows org-workspace
pl plan
stv state-version
stvs state-versions
!
}
obj_alias ()
{
  ALIAS=$(echo $(aliases | awk -v OBJ=$OBJECT '{if ($1 == OBJ) {print $2}}'))
  echo ${ALIAS:-$OBJECT}
}

# List the commands and their inputs
list-commands ()
{
  commands | awk '{printf("%s %s %s\n",$1,$2,$4)}' | awk -F"/" '{printf("%s ",$1)
                                                          for (i = 2; i <= NF; i++) {
                                                          if ( $i ~ "^{.*}$" ) printf("%s ",$i)
                                                          if ( $i ~ "filter" ) printf("%s ", substr($i,index($i,"=")+1) )
                                                          }                                                   
                                                          print ""
                                                         }'
}

set_vars ()
{
  commands | awk -v OBJ=$OBJECT -v ACT=$ACTION '{if ($1 == OBJ && $2 == ACT) printf("HTTP_OP=%s;THE_PATH=%s",$3,$4)}'
}

inputs ()
{
  list-commands | awk -v OBJ=$OBJECT -v ACT=$ACTION '{if ($1 == OBJ && $2 == ACT) print $0}' | cut -d ' ' -f 3-
}

get_token ()
{
  TOKEN=$(awk -v URL=$API_HOST '{if ($2 ~ URL) {getline;print $3}}' < ~/.terraformrc | sed 's/"//g')
  if [[ ! "$TOKEN" ]]; then
     error "No token found in ~/.terraformrc for $API_HOST"
  fi
}

error ()
{
  echo $(date) :: $1
  exit 1
}

usage ()
{
  echo "Usage: $0 [-h API_URL] object action [params]"
  list-commands
  return
}

export TZ=UTC

API_SCHEME=https
API_HOST=scalr.io
API_URL=${API_SCHEME}://${API_HOST}/api/iacp/v3
PROFILE=preview

while getopts ":h:p:" opt; do
  case ${opt} in
    h ) API_URL=$OPTARG ;;
    p ) PROFILE=$OPTARG ;;
    \? ) error "Invalid Option(s) specified" ;;
  esac
done

typeset -i SHIFT=$OPTIND-1
shift $SHIFT

get_token

OBJECT=$1
shift

if [[ $OBJECT == "help" ]]; then
   usage
   exit
fi

ACTION=$1
shift

if [[ $ACTION == "help" ]]; then
   usage | awk -v OBJ=$OBJECT '{if ($1 == OBJ || $1 == "Usage:") print $0}'
   exit
fi

# convert alias
OBJECT=$(obj_alias)

# Check we have the right number of inputs on the command line

if [[ $(inputs | wc -w) -ne $# ]]; then
   error "Wrong number of values! $(list-commands | awk -v OBJ=$OBJECT -v ACT=$ACTION '{if ($1 == OBJ && $2 == ACT) print $0}')"
fi

# This eval set HTTP_OP and THE_PATH from the string returned by set_vars()
eval $(set_vars)

if [[ ! "$THE_PATH" ]]; then
   error "Invalid command!"
fi

# Now change the placeholders to the input vars ($1, $2 etc)
typeset -i IND=0

for IN in $(inputs)
do
  IND=$IND+1
  THE_PATH=$(echo $THE_PATH | sed 's/'${IN}'/\$'${IND}'/')
done

eval THE_PATH=$THE_PATH

TEMP_FILE=/var/tmp/$(basename $0).$$.json

# For updates get the current settings
if [[ $ACTION == "update" ]]; then
   HTTP_OP_ORIG=$HTTP_OP
   HTTP_OP=GET

   api | jq '.' > $TEMP_FILE

   HTTP_OP=$HTTP_OP_ORIG

   vi $TEMP_FILE

fi

# For create provide a template
if [[ $ACTION == "create" || $ACTION == "publish" ]]; then
   cp templates/$OBJECT-$ACTION.json $TEMP_FILE

   vi $TEMP_FILE

fi

# Create, Modify and many actions require a Body
# Need a simple input mechanism to generate required JSON
# Simple values are key=value
# Nested values can be key.key=value
# Arrays are implied by repetion of the same key=value pair

api | jq '.'

rm -f $TEMP_FILE
