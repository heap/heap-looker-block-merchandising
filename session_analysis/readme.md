This pattern redefines sessions without the Heap session id and joins with the Heap event tables.  This may be needed if there are multiple Heap session ids associated with a single user id during the same time period.  This can happen with certain mobile devices or browsers that automatically delete cookies.

In this example, we'll use pseudocode from a fictional ecommerce site because the Heap event tables will be different for every Heap implementation.  The tables `home`, `product` and `add_to_cart` are fictional, but all other tables referenced are universal to Heap implementations.
