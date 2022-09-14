import ballerina/http;
import ballerina/io;
import ballerina/lang.runtime;

type ItemAllocation record {
    # Unique ID of order
    readonly string orderId;
    # Email of the user who's plcing the order
    string email;
    # ID of the inventory item
    string itemId;
    # Number of items to order
    int requiredCount;
    # Succeed payment on inital order placement
    boolean? succeedPayment;
    # Succeed order dispatch on initial order placement
    boolean? succeedDispatch;
};

int count = 0;

service / on new http:Listener(9091) {
    # Handle inventory item placement
    # + return - Inventory item
    resource function post inventory(@http:Payload ItemAllocation payload) returns ItemAllocation {
        count = count + 1;
        if((payload.itemId == "1") && (count % 2 == 0)){
            io:println("sleeping");
            runtime:sleep(60);
        }
        return payload;
    }

    # Health check to check if the service is running
    # + return - string
    resource function get inventory/health() returns string {
        return "running";
    }
}

