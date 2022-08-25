import ballerina/http;
import ballerina/io;
import ballerina/random;
import ballerina/lang.runtime;

# Order service base URL
configurable string order_service_url = "http://localhost:9090";
# Order service API Key header
configurable string order_api_key = "";

# Table to keep track of the failed payments
table<Payment> key(orderId) failedPayments = table [];

function getRandomBool() returns boolean {
    int|error randomInteger = random:createIntInRange(1, 3);
    if (randomInteger is error) {
        return false;
    }
    return randomInteger % 2 == 0;
}

function paymentsToXml(Payment[] payments) returns xml {
    // Uses a template containing a query expression, which also contains a template.
    return xml `<data>${from var {orderId, email, itemId, requiredCount, succeedDispatch, succeedPayment} in payments
        select xml `<payment><orderId>${orderId}</orderId><email>${email}</email><itemId>${itemId}</itemId><requiredCount>${requiredCount}</requiredCount><succeedDispatch>${succeedDispatch}</succeedDispatch><succeedPayment>${succeedPayment}</succeedPayment></payment>`}</data>`;
}

service / on new http:Listener(9092) {
    # Handle payment for an order
    # + return - Payment request
    resource function post payment(@http:Payload xml item) returns xml|error {
        PaymentRequest paymentItem = {
            orderId: "",
            email: "",
            itemId: "",
            requiredCount: 0,
            succeedDispatch: true,
            succeedPayment: true
        };
        foreach xml child in item.children() {
            string childStr = child.toString();
            if (childStr.trim() != "") {
                string itemKey = childStr.substring(1, <int>childStr.indexOf(">"));
                string itemVal = child.data();

                match itemKey {
                    "orderId" => {
                        paymentItem.orderId = itemVal;
                    }
                    "email" => {
                        paymentItem.email = itemVal;
                    }
                    "itemId" => {
                        paymentItem.itemId = itemVal;
                    }
                    "requiredCount" => {
                        paymentItem.requiredCount = check int:fromString(itemVal);
                    }
                    "succeedDispatch" => {
                        paymentItem.succeedDispatch = itemVal == "true";
                    }
                    "succeedPayment" => {
                        paymentItem.succeedPayment = itemVal == "true";
                    }
                }
            }
        }

        if (paymentItem.succeedPayment == true) {
            // payment succeeded
            return item;
        } else {
            // payment failed

            Payment paymentReq = {
                ...paymentItem
            };
            failedPayments.put(paymentReq);
            return error(string `Payment failed for order ${paymentItem.orderId}`);
        }
    }

    # Get list of failed item payments
    # + return - Payment list
    resource function get payment/failed() returns xml|error {
        if (getRandomBool()) {
            io:println("Randomly sleeping");
            runtime:sleep(60);
            return error(string `Request randomly failed`);
        }
        
        return paymentsToXml(failedPayments.toArray());
    }

    # Retry payments that failed previously
    # + return - List of successfull payments
    resource function post payment/retry_failed() returns xml|error {
        if (getRandomBool()) {
            io:println("Randomly sleeping");
            runtime:sleep(60);
            return error(string `Request randomly failed`);
        }

        Payment[] succeededPayments = [];
        foreach Payment item in failedPayments {
            http:Client|error orderEndpoint = new (order_service_url);
            if (!(orderEndpoint is error)) {
                string|error orderResponse = orderEndpoint->post("/order/handle_payment_retry", item, {"API-Key": order_api_key});
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

        return paymentsToXml(succeededPayments);
    }

    # Health check to check if the service is running
    # + return - string
    resource function get payment/health() returns string {
        return "running";
    }
}
