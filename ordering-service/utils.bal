import ballerina/http;

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


function itemToXml(ItemAllocation item) returns xml {
    // Uses a template containing a query expression, which also contains a template.
    return xml `<payment><orderId>${item.orderId}</orderId><email>${item.email}</email><itemId>${item.itemId}</itemId><requiredCount>${item.requiredCount}</requiredCount></payment>`;
}