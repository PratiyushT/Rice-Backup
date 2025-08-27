# Folder Structure
src/
├── lib.rs
├── main.rs
├── money/
│   └── mod.rs
├── inventory/
│   └── mod.rs
├── orders/
│   └── mod.rs
├── errors.rs
├── ids.rs
└── util.rs

## General Modules Guidelines
```rust
//Filename -> lib.rs

/* Importing various modules for re-export */
pub mod money
//..
//..
//..

/*Re-export common items*/
pub use money::{whatever_you_want_to_export};


//Filename -> main.rs
//Usage in main.rs

use project_name::item_name
```
---

# Project: CaféPOS — a tiny point-of-sale and order book
Design and implement a command-free library crate cafepos that manages inventory, orders, and pricing for a café. It must expose a clean API and an internal module layout. Add unit tests only. No CLI.

Core domain
SKU, OrderId, CustomerId are newtype wrappers over integers.

Money is a cents-based currency type.

Inventory holds Items keyed by SKU.

OrderBook holds Orders keyed by OrderId and kept ordered.

Order contains a customer, a vector of LineItems, and a Status enum.

Functional requirements
Create items and manage inventory

Add, restock, and deplete stock.

Validate names and stock quantities.

Index inventory by SKU using the indexing traits.

Create orders and compute totals

Build an order from a CustomerId and a list of (SKU, qty).

Reject an order if any SKU is unknown or insufficient stock exists.

Deduct stock on OrderStatus::Confirmed.

Compute totals with taxes and optional percentage discount.

Search and reporting

Search inventory by a name prefix using &str and return matching immutable slices.

Provide iterators to:

iterate inventory in arbitrary order, and

iterate orders in ascending OrderId order.

Produce a report of the top N selling SKUs using iterator combinators.

Error handling

All fallible APIs return Result<_, CafeError>.

Include variants like InvalidName, DuplicateSku, UnknownSku, InsufficientStock, InvalidQuantity, OrderNotFound, and StateConflict.

Two-state logic

OrderStatus has at least Draft, Confirmed, Cancelled, Fulfilled.

Enforce legal transitions with match and return errors on illegal moves.

Technical constraints that map to your topics
Syntax and basic calculator items

In Money, implement add_tax(rate_bps: u32) and apply_discount(percent_bps: u32) using integers, branching, and safe arithmetic.

Provide a saturating_sub helper in Money to demonstrate saturating arithmetic.

Add a tiny factorial function in a private util module and unit test it to cover loops and panics on invalid input.

Structs, validation, modules, visibility, encapsulation

Split into modules: money, ids, inventory, orders, errors, util.

Constructors validate input and return Result. Fields are private with getters and minimal setters.

Ownership, stack vs heap, references, destructors

Item holds a heap-allocated description String.

Implement Drop for a small debug guard type BorrowGuard used in tests to prove drop order.

Traits

Derive Debug, Clone, PartialEq, Eq, Ord, PartialOrd where sensible.

Implement Display for SKU and Money.

Implement From<u64> and TryFrom<&str> for SKU with validation.

Implement Add and Sub for Money.

Implement Index<SKU> and IndexMut<SKU> for Inventory.

Implement IntoIterator for &Inventory yielding (&SKU, &Item).

Implement IntoIterator for &OrderBook yielding &Order in OrderId order.

Use impl Trait in function signatures that return iterators.

Enums and error traits

Status enum with data in at least one variant, for example Cancelled { reason: String }.

CafeError implements std::error::Error and Display.

Use From or TryFrom bridges where helpful.

Packages and dependencies

No external crates are required, but you may use thiserror if you want a second version of CafeError. Keep one version without it to show both styles.

Collections and iteration

Inventory uses HashMap<SKU, Item>.

OrderBook uses BTreeMap<OrderId, Order>.

Show vector resizing when building LineItems.

Use filter, map, fold, any, all in reporting functions.

Lifetimes, string slices, slices

The name-prefix search takes &str and returns a borrowed slice view over a Vec<&Item> or similar.

Provide APIs that accept &[LineItem] and &mut [LineItem] to apply bulk discounts.

Two states and let-else

In confirm_order, use let Some(order) = ... else { return Err(CafeError::OrderNotFound) };.

API sketch
Money(u64) newtype with arithmetic and conversions.

SKU(u32), OrderId(u64), CustomerId(u64).

struct Item { sku: SKU, name: String, price: Money, stock: u32 }

struct Inventory { map: HashMap<SKU, Item> }

enum OrderStatus { Draft, Confirmed, Cancelled { reason: String }, Fulfilled }

struct LineItem { sku: SKU, qty: u32 }

struct Order { id: OrderId, customer: CustomerId, lines: Vec<LineItem>, status: OrderStatus }

struct OrderBook { by_id: BTreeMap<OrderId, Order>, next_id: u64 }

enum CafeError { .. }

Acceptance tests you must write
Inventory

Creating valid and invalid items.

Indexing with inventory[sku].

Iterating for (sku, item) in &inventory { ... }.

Orders

Creating a draft with unknown SKU returns error.

Confirming deducts stock.

Illegal transition Draft → Fulfilled returns error.

Cancelling with reason stores the reason.

Money

Addition, subtraction with saturating behavior.

Tax and discount math with integer rounding rules you document.

Search and slices

Prefix search with &str returns borrowed views and respects lifetimes.

Iteration and ordering

for order in &order_book yields Orders in ascending OrderId.

Converting a Vec<Order> to OrderBook via FromIterator is a bonus and should preserve or regenerate order deterministically.

Combinators

Top N selling SKUs using iterators only, no indexing loops.

Stretch goals
Add a Promo enum with data that applies fixed or percentage discounts using match.

Add RwLock<OrderBook> and a single concurrency test using threads that read orders while one thread adds.

Serialize SKU and Money with Display and FromStr for round-trip tests.

What you will prove
You can design modules with visibility control.

You can model data with enums and newtypes.

You can implement and use traits, including operator overloading and indexing.

You can choose proper collections and expose ordered and unordered iteration.

You can manage lifetimes for string slices and borrowed views.

You can build Result-driven APIs with custom errors.

You can write iterator-centric code without manual indexing.
