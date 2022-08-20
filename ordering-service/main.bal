import ballerina/http;
import ballerina/uuid;

# Inventory service base URL
configurable string invetentory_service_url = "http://localhost:9091";
# Inventory service API Key header
configurable string inventory_api_key = "";
# Payment service base URL
configurable string payment_service_url = "http://localhost:9092";
# Payment service API Key header
configurable string payment_api_key = "";
# Dispatch service base URL
configurable string dispatch_service_url = "http://localhost:9093";
# Dispatch service API Key header
configurable string dispatch_api_key = "";

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
        json|error inventoryResponse = inventortEndpoint->post("/inventory/allocate", inventoryAllocation, {"API-Key": inventory_api_key});

        if (inventoryResponse is error) {
            return acceptedResponse("inventory service");
        }

        http:Client paymentEndpoint = check new (payment_service_url);
        json|error paymentResponse = paymentEndpoint->post("/payment", inventoryAllocation, {"API-Key": payment_api_key});

        if (paymentResponse is error) {
            return acceptedResponse("payment service");
        }

        http:Client dispatchEndpoint = check new (dispatch_service_url);
        json|error dispatchResponse = dispatchEndpoint->post("/dispatch", inventoryAllocation, {"API-Key": dispatch_api_key});

        if (dispatchResponse is error) {
            return acceptedResponse("dispatch service");
        }

        return orderPlacedResponse();
    }

    # Get list of failed orders
    # + return - List of failed orders at each stage
    resource function get 'order/failed() returns json|error {

        http:Client inventortEndpoint = check new (invetentory_service_url);
        json inventoryResponse = check inventortEndpoint->get("/inventory/failed", {"API-Key": inventory_api_key});

        http:Client paymentEndpoint = check new (payment_service_url);
        json paymentResponse = check paymentEndpoint->get("/payment/failed", {"API-Key": payment_api_key});

        http:Client dispatchEndpoint = check new (dispatch_service_url);
        json dispatchResponse = check dispatchEndpoint->get("/dispatch/failed", {"API-Key": dispatch_api_key});

        return {
            "inventory": inventoryResponse,
            "payment": paymentResponse,
            "dispatch": dispatchResponse
        };
    }

    # Retry all the failed orders in inventory, payment and dispatch services
    # + return - List of failed orders at each stage
    resource function post 'order/retry_failed() returns json|error {

        http:Client inventortEndpoint = check new (invetentory_service_url);
        json inventoryResponse = check inventortEndpoint->post("/inventory/retry_failed", {}, {"API-Key": inventory_api_key});

        http:Client paymentEndpoint = check new (payment_service_url);
        json paymentResponse = check paymentEndpoint->post("/payment/retry_failed", {}, {"API-Key": payment_api_key});

        http:Client dispatchEndpoint = check new (dispatch_service_url);
        json dispatchResponse = check dispatchEndpoint->post("/dispatch/retry_failed", {}, {"API-Key": dispatch_api_key});

        return {
            "inventory": inventoryResponse,
            "payment": paymentResponse,
            "dispatch": dispatchResponse
        };
    }

    # Handle order dispatch and payment handling for successful inventory retry invocation
    # + return - Order placed or accepted response
    resource function post 'order/handle_inventory_retry(@http:Payload ItemAllocation item) returns http:Response|error {
        http:Client paymentEndpoint = check new (payment_service_url);
        json|error paymentResponse = paymentEndpoint->post("/payment", item, {"API-Key": payment_api_key});

        if (paymentResponse is error) {
            return acceptedResponse("payment service");
        }

        http:Client dispatchEndpoint = check new (dispatch_service_url);
        json|error dispatchResponse = dispatchEndpoint->post("/dispatch", item, {"API-Key": dispatch_api_key});

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
        json|error dispatchResponse = dispatchEndpoint->post("/dispatch", item, {"API-Key": dispatch_api_key});

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

    # Health check to check if the service is running
    # + return - string
    resource function get 'order/health() returns string {
        return "running";
    }
}
