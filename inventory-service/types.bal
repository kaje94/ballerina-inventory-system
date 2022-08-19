type NewItem record {|
    # ID of the inventory item
    string id;
    # Name of the inventory item
    string name;
    # Available quantity of the inventory item
    int quantity;
|};

type ItemAllocation record {
    # Unique ID of order
    readonly string orderId;
    # Email of the user who's plcing the order
    string email;
    # ID of the inventory item
    string itemId;
    # Number of items to order
    int requiredCount;
    # Succeed payment on inital order placement
    boolean? succeedPayment;
    # Succeed order dispatch on initial order placement
    boolean? succeedDispatch;
};

type Inventory record {
    # ID of the inventory item to update
    readonly string id;
    # New name of the inventory item
    string name;
    # New available quantity of the inventory item
    int quantity;
};
