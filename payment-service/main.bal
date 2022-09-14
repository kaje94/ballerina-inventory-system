import ballerina/http;
import ballerina/log;

type Payment record {
    # Unique ID of order
    readonly string orderId;
    # Email of the user who's plcing the order
    string email;
    # ID of the inventory item
    string itemId;
    # Number of items to order
    int requiredCount;
};

type PaymentRequest record {
    # Unique ID of order
    string orderId;
    # Email of the user who's plcing the order
    string email;
    # ID of the inventory item
    string itemId;
    # Number of items to order
    int requiredCount;
};

service / on new http:Listener(9092) {
    # Handle payment for an order
    # + return - Payment request
    resource function post payment(@http:Payload xml item) returns xml|error {
        log:printInfo("Payment service invoked successfully");
        return item;
    }

    # Health check to check if the service is running
    # + return - string
    resource function get payment/health() returns string {
        return "running";
    }
}
