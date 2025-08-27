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

# Guidelines

