import ballerina/http;
import ballerina/io;
import wso2/choreo.sendemail;

# Generate and return 202 order accepted response
# + area - Area where the order is currently at. eg: inventory, payment, etc
# + return - Order accepted http:Response
function acceptedResponse(string area) returns http:Response {
    http:Response res = new http:Response();
    res.statusCode = 202;
    res.setTextPayload(string `Order accepted. currently being processed by ${area}`);
    return res;
}

# Generate and return 200 order placed response
# + return - Order placed http:Response
function orderPlacedResponse() returns http:Response {
    http:Response res = new http:Response();
    res.statusCode = 200;
    res.setTextPayload("Order placed");
    return res;
}

# Send an email to the user who placed an order confirming that the order is placed
# + emailAddress - Email address to which the email needs to be sent
function sendOrderPlacedMail(string emailAddress) {
    io:println(string `Sending order completion email to ${emailAddress}`);
    string mailSubject = "Your order is complete";
    string mailBody = "Your order has been dispatched to your address after verifying your payment and inventory availablity.";

    sendemail:Client|error sendemailEp = new ();
    if (!(sendemailEp is error)) {
        string|error emailRes = sendemailEp->sendEmail(recipient = emailAddress, subject = mailSubject, body = mailBody);
        if (!(emailRes is error)) {
            io:println("Failed to send email notification");
        }
    }
}
