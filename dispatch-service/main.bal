import ballerina/http;
import ballerina/io;
import ballerina/random;
import ballerina/lang.runtime;

# Order service base URL
configurable string order_service_url = "http://localhost:9090";
# Order service API Key header
configurable string order_api_key = "";

# Table to keep track of the failed delivery dispatches
table<Dispatch> key(orderId) failedDispatches = table [];

function getRandomBool() returns boolean{
    int|error randomInteger = random:createIntInRange(1, 3);
    if(randomInteger is error){
        return false;
    }
    return randomInteger % 2 == 0;
}

service / on new http:Listener(9093) {
    # Handle dispatch for an order
    # + return - Dispatch request
    resource function post dispatch(@http:Payload Dispatch item) returns Dispatch|error {
        if (item.succeedDispatch == true) {
            // dispatch succeeded
            return item;
        } else {
            // dispatch failed
            failedDispatches.put(item);
            return error(string `Dispatch failed for order ${item.orderId}`);
        }
    }

    # Get list of failed item dispatches
    # + return - Dispatch list
    resource function get dispatch/failed() returns Dispatch[]|error {
        if (getRandomBool()) {
            io:println("Randomly sleeping");
            runtime:sleep(60);
            return error(string `Request randomly failed`);
        }

        return failedDispatches.toArray();
    }

    # Retry dispatches that failed previously
    # + return - List of successfull dispatches
    resource function post dispatch/retry_failed() returns Dispatch[]|error {
        if (getRandomBool()) {
            io:println("Randomly sleeping");
            runtime:sleep(60);
            return error(string `Request randomly failed`);
        }

        Dispatch[] succeededDispatches = [];
        foreach Dispatch item in failedDispatches {
            http:Client|error orderEndpoint = new (order_service_url);
            if (!(orderEndpoint is error)) {
                string|error orderResponse = orderEndpoint->post("/order/handle_dispatch_retry", item, {"API-Key": order_api_key});
                if (!(orderResponse is error)) {
                    succeededDispatches.push(item);
                } else {
                    io:println(string `Failed to retry ${item.itemId} ${orderResponse.toString()}`);
                }
            }
        }

        foreach Dispatch item in succeededDispatches {
            Dispatch _ = failedDispatches.remove(item.orderId);
        }

        return succeededDispatches;
    }

    # Health check to check if the service is running
    # + return - string
    resource function get dispatch/health() returns string {
        return "running";
    }
}
