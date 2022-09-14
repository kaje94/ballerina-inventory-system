import ballerina/http;
import ballerina/log;

type Dispatch record {
    # Unique ID of order
    readonly string orderId;
    # Email of the user who's plcing the order
    string email;
    # ID of the inventory item
    string itemId;
    # Number of items to order
    int requiredCount;
};

service / on new http:Listener(9093) {

    resource function post dispatch(@http:Payload Dispatch payload) returns Dispatch {
        log:printInfo("Dispatch service invoked successfully");
        return payload;
    }

    # Health check to check if the service is running
    # + return - string
    resource function get dispatch/health() returns string {
        return "running";
    }
}
