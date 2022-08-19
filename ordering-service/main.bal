import ballerina/http;
import ballerina/uuid;

# Inventory service base URL
configurable string invetentory_service_url = "http://localhost:9091";
# Payment service base URL
configurable string payment_service_url = "http://localhost:9092";
# Dispatch service base URL
configurable string dispatch_service_url = "http://localhost:9093";


service / on new http:Listener(9090) {
    # Place an order with item id and quanitity
    # + return - Order placed or accepted response
    resource function post 'order(@http:Payload OrderItem item) returns http:Response|error {
        ItemAllocation inventoryAllocation = {
            orderId: uuid:createType1AsString(),
            email: item.email,
            itemId: item.itemId,
            requiredCount: item.quantity,
            succeedPayment: item.succeedPayment,
            succeedDispatch: item.succeedDispatch
        };

        http:Client inventortEndpoint = check new (invetentory_service_url);
        json|error inventoryResponse = inventortEndpoint->post("/inventory/allocate", inventoryAllocation);

        if (inventoryResponse is error) {
            return acceptedResponse("inventory service");
        }

        http:Client paymentEndpoint = check new (payment_service_url);
        json|error paymentResponse = paymentEndpoint->post("/payment", inventoryAllocation);

        if (paymentResponse is error) {
            return acceptedResponse("payment service");
        }

        http:Client dispatchEndpoint = check new (dispatch_service_url);
        json|error dispatchResponse = dispatchEndpoint->post("/dispatch", inventoryAllocation);

        if (dispatchResponse is error) {
            return acceptedResponse("dispatch service");
        }

        return orderPlacedResponse();
    }

    # Handle order dispatch and payment handling for successful inventory retry invocation
    # + return - Order placed or accepted response
    resource function post 'order/handle_inventory_retry(@http:Payload ItemAllocation item) returns http:Response|error {
        http:Client paymentEndpoint = check new (payment_service_url);
        json|error paymentResponse = paymentEndpoint->post("/payment", item);

        if (paymentResponse is error) {
            return acceptedResponse("payment service");
        }

        http:Client dispatchEndpoint = check new (dispatch_service_url);
        json|error dispatchResponse = dispatchEndpoint->post("/dispatch", item);

        if (dispatchResponse is error) {
            return acceptedResponse("dispatch service");
        }

        sendOrderPlacedMail(item.email);

        return orderPlacedResponse();
    }

    # Handle order dispatch handling for successful payment retry invocation
    # + return - Order placed or accepted response
    resource function post 'order/handle_payment_retry(@http:Payload ItemAllocation item) returns http:Response|error {
        http:Client dispatchEndpoint = check new (dispatch_service_url);
        json|error dispatchResponse = dispatchEndpoint->post("/dispatch", item);

        if (dispatchResponse is error) {
            return acceptedResponse("dispatch service");
        }

        sendOrderPlacedMail(item.email);

        return orderPlacedResponse();
    }

    # Handle order email notification handling for successful ordre dispatch retry invocation
    # + return - Order placed or accepted response
    resource function post 'order/handle_dispatch_retry(@http:Payload ItemAllocation item) returns http:Response|error {
        sendOrderPlacedMail(item.email);

        return orderPlacedResponse();
    }
}
