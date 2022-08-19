import ballerina/http;
import ballerina/io;

configurable string order_service_url = "http://localhost:9090";

# Table to keep track of the failed payments
table<Payment> key(orderId) failedPayments = table [];

service / on new http:Listener(9092) {
    # Handle payment for an order
    # + return - Payment request
    resource function post payment(@http:Payload Payment item) returns Payment|error {
        if (item.succeedPayment == true) {
            // payment succeeded
            return item;
        } else {
            // payment failed
            failedPayments.put(item);
            return error(string `Payment failed for order ${item.orderId}`);
        }
    }

    # Get list of failed item payments
    # + return - Payment list
    resource function get payment/failed() returns Payment[] {
        return failedPayments.toArray();
    }

    # Retry payments that failed previously
    # + return - List of successfull payments
    resource function post payment/retry_failed() returns Payment[] {
        Payment[] succeededPayments = [];
        foreach Payment item in failedPayments {
            http:Client|error orderEndpoint = new (order_service_url);
            if (!(orderEndpoint is error)) {
                string|error orderResponse = orderEndpoint->post("/order/handle_payment_retry", item);
                if (!(orderResponse is error)) {
                    succeededPayments.push(item);
                } else {
                    io:println(string `Failed to retry ${item.itemId} ${orderResponse.toString()}`);
                }
            }
        }

        foreach Payment item in succeededPayments {
            Payment _ = failedPayments.remove(item.orderId);
        }

        return succeededPayments;
    }
}
