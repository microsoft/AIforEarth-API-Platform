import os
import json

def customize_task_management_policy(get_fun_url):
    response_url = get_fun_url + '&taskId='
    taskmanagement_set_url_value='<policies><inbound><send-request response-variable-name="context.Response" ignore-error="false"><set-url>@("' + response_url + '" + context.Request.MatchedParameters["taskId"])</set-url><set-method>GET</set-method></send-request><return-response response-variable-name="context.Response" /></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
   
    policy_struct = { 'properties' : { 'format': 'rawxml', 'value': taskmanagement_set_url_value } }

    with open('customized_task_management_policy.json', 'w') as outfile:
        json.dump(policy_struct, outfile)

def customize_async_api_policy(ingress_ip, url_template, upsert_fun_url):

    with open('./APIManagement/request_policy.xml') as request_policy:
        url_string = request_policy.read(-1).replace('BACKEND_URL', '\"' + ingress_ip + '\"')
        url_string = url_string.replace('URL_TEMPLATE', '\"' + url_template + '\"')
        url_string = url_string.replace('SET_URL', upsert_fun_url)

        policy_struct = { 'properties' : { 'format': 'rawxml', 'value': url_string } }

        with open('customized_async_api_policy.json', 'w') as outfile:
            json.dump(policy_struct, outfile)

def customize_backend_policy(cluster_url):
    set_url_value='<policies><inbound><base /><set-backend-service base-url=\"' + cluster_url + '\" /></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
    policy_struct = { 'properties' : { 'format': 'rawxml', 'value': set_url_value } }

    with open('customized_request_backend_policy.json', 'w') as outfile:
        json.dump(policy_struct, outfile)

def customize_api_management_creation_body(api_management_email, api_management_org_name, api_management_sku, api_management_region):
    with open('./APIManagement/api_management_body.json') as api_management_body_file:
        api_management_body = json.load(api_management_body_file)

        api_management_body['properties']['publisherEmail'] = api_management_email
        api_management_body['properties']['publisherName'] = api_management_org_name

        api_management_body['sku']['name'] = api_management_sku

        api_management_body['location'] = api_management_region

        with open('customized_api_management_body.json', 'w') as outfile:
            json.dump(api_management_body, outfile)
