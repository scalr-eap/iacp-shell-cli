#!/bin/bash

api()
{

  if [[ $HTTP_OP = "POST" || $HTTP_OP = "PATCH" ]]; then
     curl -s -X ${HTTP_OP} ${API_URL}${THE_PATH} \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/vnd.api+json" \
	              --data "@/var/tmp/$0.$$.json"
  else
         curl -s -X ${HTTP_OP} ${API_URL}${THE_PATH} \
                    -H "Authorization: Bearer $TOKEN" \
                    -H "Content-Type: application/vnd.api+json"
  fi

}

commands()
{
cat << !
account                get     GET /api/iacp/v3/account/details
apply                  get     GET /api/iacp/v3/applies/{apply}
configuration-version  get     GET /api/iacp/v3/configuration-versions/{configuration_version}
ingress-attributes     get     GET /api/iacp/v3/configuration-versions/{configuration_version}/ingress-attributes
configuration-versions list    GET /api/iacp/v3/workspaces/{workspace}/configuration-versions
configuration-versions create  POST /api/iacp/v3/workspaces/{workspace}/configuration-versions
cost-estimate          get     GET /api/iacp/v3/cost-estimates/{cost_estimate}
cost-estimates         get-log GET /api/iacp/v3/cost-estimates/{cost_estimate}/output
idps                   list    GET /api/iacp/v3/identity-providers
idp                    get     GET /api/iacp/v3/identity-providers/{id}
organizations          list    GET /api/iacp/v3/organizations
organization           get     GET /api/iacp/v3/organizations/{organization}
module                 create  POST /api/iacp/v3/organizations/{organization}/registry-modules
module                 publish POST /api/iacp/v3/registry-modules
module                 delete  POST /api/iacp/v3/registry-modules/actions/delete/{organization}/{module_name}
module-provider        delete  POST /api/iacp/v3/registry-modules/actions/delete/{organization}/{module_name}/{provider_name}
module-version         delete  POST /api/iacp/v3/registry-modules/actions/delete/{organization}/{module_name}/{provider_name}/{version}
module                 get     GET /api/iacp/v3/registry-modules/{module}
module                 get-np  GET /api/iacp/v3/registry-modules/{organization}/{module_name}/{module_provider}
module                 resync  POST /api/iacp/v3/registry-modules/{organization}/{module_name}/{module_provider}/resync
module                 create-version POST /api/iacp/v3/registry-modules/{organization}/{module_name}/{module_provider}/versions
module                 resync-version POST /api/iacp/v3/registry-modules/{organization}/{module_name}/{module_provider}/{version}/resync
workspaces             list    GET /api/iacp/v3/organizations/{organization}/workspaces
workspace              create  POST /api/iacp/v3/organizations/{organization}/workspaces
org-workspace          delete  DELETE /api/iacp/v3/organizations/{organization}/workspaces/{workspace_name}
org-workspace          get     GET /api/iacp/v3/organizations/{organization}/workspaces/{workspace_name}
org-workspace          update  PATCH /api/iacp/v3/organizations/{organization}/workspaces/{workspace_name}
workspace              delete  DELETE /api/iacp/v3/workspaces/{workspace}
workspace              get     GET /api/iacp/v3/workspaces/{workspace}
workspace              update  PATCH /api/iacp/v3/workspaces/{workspace}
workspace              lock    POST /api/iacp/v3/workspaces/{workspace}/actions/lock
workspace              unlock  POST /api/iacp/v3/workspaces/{workspace}/actions/unlock
plan                   get     GET /api/iacp/v3/plans/{plan}
run                    create  POST /api/iacp/v3/runs
run                    get     GET /api/iacp/v3/runs/{run}
run                    confirm POST /api/iacp/v3/runs/{run}/actions/apply
run                    cancel  POST /api/iacp/v3/runs/{run}/actions/cancel
run                    discard POST /api/iacp/v3/runs/{run}/actions/discard
run                    force-cancel POST /api/iacp/v3/runs/{run}/actions/force-cancel
run                    policy-input POST /api/iacp/v3/runs/{run}/policy-input
runs                   list    GET /api/iacp/v3/workspaces/{workspace}/runs
state-versions         list    GET /api/iacp/v3/state-versions
state-version          get     GET /api/iacp/v3/state-versions/{state_version}
state-version          get-current GET /api/iacp/v3/workspaces/{workspace}/current-state-version
state-version          create  POST /api/iacp/v3/workspaces/{workspace}/state-versions
users                  list    GET /api/iacp/v3/users
user                   get     GET /api/iacp/v3/users/{id}
vars                   list    GET /api/iacp/v3/vars
var                    create  POST /api/iacp/v3/vars
var                    delete  DELETE /api/iacp/v3/vars/{var}
var                    get     GET /api/iacp/v3/vars/{var}
var                    update  PATCH /api/iacp/v3/vars/{var}
!
}

aliases ()
{
  cat << !
acc  account
accs accounts
app apply
cfv  configuration_version
cfvs configuration_versions
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
stv state_version
stvs state_versions
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
                                                          if ( $i ~ "{.*}" ) printf("%s ",$i)
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
API_HOST=my.scalr.com
API_URL=${API_SCHEME}://${API_HOST}

while getopts ":h:" opt; do
  case ${opt} in
    h ) API_URL=$OPTARG ;;
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
if [[ $ACTION == "create" ]]; then
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
