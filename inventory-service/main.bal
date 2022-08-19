import ballerina/http;
import ballerina/io;

# Order service base URL
configurable string order_service_url = "http://localhost:9090";

service / on new http:Listener(9091) {
    # Get all items in the inventory
    # + return - List of inventory items
    resource function get inventory() returns Inventory[] {
        return inventroyItems.toArray();
    }

    # Get inventory item for given item id
    # + return - Inventory item
    resource function get inventory/[string id]() returns Inventory|error {
        Inventory? found = findInventoryItem(id);
        if found is () {
            return error(string `inventory not found for item: ${id}`);
        } else {
            return found;
        }
    }

    # Create or update an inventory item
    # + return - Inventory item
    resource function post inventory(@http:Payload NewItem payload) returns Inventory|error {
        Inventory newItem = {
            id: payload.id,
            name: payload.name,
            quantity: payload.quantity
        };
        inventroyItems.put(newItem);
        return newItem;

    }

    # Delete an inventory item
    # + return - Inventory item
    resource function delete inventory/[string id]() returns Inventory|error {
        Inventory removed = inventroyItems.remove(id);
        return removed;
    }

    # Reduce the avaialble inventory quantity for given item
    # + return - Inventory allocation
    resource function post inventory/allocate(@http:Payload ItemAllocation payload) returns ItemAllocation|error {
        Inventory? inventory = findInventoryItem(payload.itemId);
        if inventory is () {
            return error(string `inventory not found for item: ${payload.itemId}`);
        }

        if payload.requiredCount > inventory.quantity {
            failedOrders.put(payload);
            return error(string `not enought quantity for item: ${payload.itemId}, needed quantity : ${payload.requiredCount}`);
        }

        inventory.quantity = inventory.quantity - payload.requiredCount;
        inventroyItems.put(inventory);
        return payload;
    }

    # Retry orders that failed due to insufficent quantity
    # + return - List of successfull allocation
    resource function post inventory/retry_failed() returns ItemAllocation[] {
        ItemAllocation[] succeededOrders = [];

        foreach ItemAllocation item in failedOrders {
            Inventory? inventory = findInventoryItem(item.itemId);
            if inventory is () {
                io:println(string `item ${item.itemId} is not found`);
            } else {
                if (inventory.quantity > item.requiredCount) {
                    http:Client|error orderEndpoint = new (order_service_url);
                    if (!(orderEndpoint is error)) {
                        string|error orderResponse = orderEndpoint->post("/order/handle_inventory_retry", item);
                        if (!(orderResponse is error)) {
                            inventory.quantity = inventory.quantity - item.requiredCount;
                            inventroyItems.put(inventory);
                            succeededOrders.push(item);
                        }else{
                            io:println(string `Failed to retry ${item.itemId} ${orderResponse.toString()}`);
                        }
                    }
                }
            }
        }

        foreach ItemAllocation item in succeededOrders {
            ItemAllocation _ = failedOrders.remove(item.orderId);
        }

        return succeededOrders;
    }

    # Get list of failed item allocations
    # + return - ItemAllocation list
    resource function get inventory/failed() returns ItemAllocation[] {
        return failedOrders.toArray();
    }
}

