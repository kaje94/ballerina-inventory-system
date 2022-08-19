# Table to keep track of the item allocation orders that failed due to insufficent available quantity
table<ItemAllocation> key(orderId) failedOrders = table [];

# Table to keep track of the items in the inventory
table<Inventory> key(id) inventroyItems = table [
        {
            id: "1",
            name: "item-1",
            quantity: 100
        },
        {
            id: "2",
            name: "item-2",
            quantity: 100
        },
        {
            id: "3",
            name: "item-3",
            quantity: 100
        },
        {
            id: "4",
            name: "item-4",
            quantity: 100
        },
        {
            id: "5",
            name: "item-5",
            quantity: 100
        }
    ];

# Find an item from the inventory list
# + id - ID of the inventory item to search
# + return - Inventory item
function findInventoryItem(string id) returns Inventory? {
    return inventroyItems[id];
}
