type OrderItem record {
    # Email of the user who's plcing the order
    string email;
    # ID of the inventory item
    string itemId;
    # Number of items to order
    int quantity;
    # Succeed payment on inital order placement
    boolean? succeedPayment;
    # Succeed order dispatch on initial order placement
    boolean? succeedDispatch;
};

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
