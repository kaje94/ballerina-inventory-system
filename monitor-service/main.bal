import ballerina/io;
import ballerina/http;

# Order service base URL
configurable string order_service_url = "http://localhost:9090";
# Order service API Key header
configurable string order_api_key = "";
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

public function main() {
    io:println("Running checks");

    http:Client|error orderEndpoint = new (order_service_url);
    if(!(orderEndpoint is error)){
        string|error orderResponse = orderEndpoint->get("/order/health", {"API-Key": order_api_key});
        if(orderResponse is error){
            io:println("Order service is not reachable");
        }
    }

    http:Client|error inventoryEndpoint = new (invetentory_service_url);
    if(!(inventoryEndpoint is error)){
        string|error inventoryResponse = inventoryEndpoint->get("/inventory/health", {"API-Key": inventory_api_key});
        if(inventoryResponse is error){
            io:println("Inventory service is not reachable");
        }
    }

    http:Client|error paymentEndpoint = new (payment_service_url);
    if(!(paymentEndpoint is error)){
        string|error paymentResponse = paymentEndpoint->get("/payment/health", {"API-Key": payment_api_key});
        if(paymentResponse is error){
            io:println("Payment service is not reachable");
        }
    }

    http:Client|error dispatchEndpoint = new (dispatch_service_url);
    if(!(dispatchEndpoint is error)){
        string|error dispatchResponse = dispatchEndpoint->get("/dispatch/health", {"API-Key": dispatch_api_key});
        if(dispatchResponse is error){
            io:println("Dispatch service is not reachable");
        }
    }

    io:println("Finished Running checks");
}