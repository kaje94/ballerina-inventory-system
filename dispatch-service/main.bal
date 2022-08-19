import ballerina/http;
import ballerina/io;

configurable string order_service_url = "http://localhost:9090";

# Table to keep track of the failed delivery dispatches
table<Dispatch> key(orderId) failedDispatches = table [];

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
    resource function get dispatch/failed() returns Dispatch[] {
        return failedDispatches.toArray();
    }

    # Retry dispatches that failed previously
    # + return - List of successfull dispatches
    resource function post dispatch/retry_failed() returns Dispatch[] {
        Dispatch[] succeededDispatches = [];
        foreach Dispatch item in failedDispatches {
            http:Client|error orderEndpoint = new (order_service_url);
            if (!(orderEndpoint is error)) {
                string|error orderResponse = orderEndpoint->post("/order/handle_dispatch_retry", item);
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
}
