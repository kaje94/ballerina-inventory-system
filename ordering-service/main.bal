import ballerina/http;
import ballerina/uuid;

# Inventory service base URL
configurable string invetentory_service_url = "";
# Inventory service API Key header
configurable string inventory_api_key = "";
# Payment service base URL
configurable string payment_service_url = "";
# Payment service API Key header
configurable string payment_api_key = "";
# Dispatch service base URL
configurable string dispatch_service_url = "";
# Dispatch service API Key header
configurable string dispatch_api_key = "";

http:ClientConfiguration httpClientOptions = {
    // Retry configuration options.
    retryConfig: {
        // Initial retry interval in seconds.
        interval: 2,
        // Number of retry attempts before giving up.
        count: 5,
        // Multiplier of the retry interval to exponentially increase
        // the retry interval.
        backOffFactor: 2.0,
        // Upper limit of the retry interval in seconds. If
        // `interval` into `backOffFactor` value exceeded
        // `maxWaitInterval` interval value,
        // `maxWaitInterval` will be considered as the retry
        // interval.
        maxWaitInterval: 120
    },
    timeout: 5
};


http:Client inventortEndpoint = check new (invetentory_service_url, httpClientOptions);
http:Client paymentEndpoint = check new (payment_service_url, httpClientOptions);
http:Client dispatchEndpoint = check new (dispatch_service_url, httpClientOptions);

type OrderItem record {
    # Email of the user who's plcing the order
    string email;
    # ID of the inventory item
    string itemId;
    # Number of items to order
    int quantity;
};

type ItemAllocation record {
    # Unique ID of order
    readonly string orderId;
    # Email of the user who's plcing the order
    string email;
    # ID of the inventory item
    string itemId;
    # Number of items to order
    int requiredCount;
};


service / on new http:Listener(9090) {
    # Place an order with item id and quanitity
    # + return - Order placed or accepted response
    resource function post 'order(@http:Payload OrderItem item) returns http:Response|error {
        ItemAllocation inventoryAllocation = {
            orderId: uuid:createType1AsString(),
            email: item.email,
            itemId: item.itemId,
            requiredCount: item.quantity
        };

        json|error inventoryResponse = inventortEndpoint->post("/inventory/allocate", inventoryAllocation, {"API-Key": inventory_api_key});
        if (inventoryResponse is error) {
            return acceptedResponse("inventory service");
        }

        xml|error paymentResponse = paymentEndpoint->post("/payment", itemToXml(inventoryAllocation), {"API-Key": payment_api_key});
        if (paymentResponse is error) {
            return acceptedResponse("payment service");
        }

        json|error dispatchResponse = dispatchEndpoint->post("/dispatch", inventoryAllocation, {"API-Key": dispatch_api_key});
        if (dispatchResponse is error) {
            return acceptedResponse("dispatch service");
        }

        return orderPlacedResponse();
    }


    # Health check to check if the service is running
    # + return - string
    resource function get 'order/health() returns string {
        return "running";
    }
}
