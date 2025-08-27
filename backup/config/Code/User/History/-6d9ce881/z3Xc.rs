use core::panic;

// TODO: Define a new `Order` type.
//   It should keep track of three pieces of information: `product_name`, `quantity`, and `unit_price`.
//   The product name can't be empty and it can't be longer than 300 bytes.
//   The quantity must be strictly greater than zero.
//   The unit price is in cents and must be strictly greater than zero.
//   Order must include a method named `total` that returns the total price of the order.
//   Order must provide setters and getters for each field.
//
// Tests are located in a different place this time—in the `tests` folder.
// The `tests` folder is a special location for `cargo`. It's where it looks for **integration tests**.
// Integration here has a very specific meaning: they test **the public API** of your project.
// You'll need to pay attention to the visibility of your types and methods; integration
// tests can't access private or `pub(crate)` items.
pub struct Order {
    product_name: String,
    quantity: u16,
    unit_price: u16,
}

impl Order {
    /* Validators */
    fn validate_name(product_name: &String) {
        if product_name.is_empty() {
            panic!("Product name cannot be empy");
        }
        if product_name.len() > 300 {
            panic!("Product name cannot be more than 300 chars");
        }
    }

    fn validate_quantity(quantity: u16) {
        if quantity < 1 {
            panic!("Quantity must be greater than 0.")
        }
    }
    fn validate_price(unit_price: u16) {
        if unit_price < 1 {
            panic!("Price must be greater than 0.")
        }
    }

    /* Getters */
    pub fn product_name(&self)->&String{
        &self.product_name
    }

    /* Contructor */
    pub fn new(product_name: String, quantity: u16, unit_price: u16) -> Order {
        Order::validate_name(&product_name);
        Order::validate_quantity(quantity);
        Order::validate_price(unit_price);

        Order {
            product_name,
            quantity,
            unit_price,
        }
    }
}
