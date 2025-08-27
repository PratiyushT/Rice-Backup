//! # Rust Rules
//!
//! 1. The **main function** is always called first in a Rust program.
//! 2. The main function must be declared as `fn main() {}`.
//! 3. The main function does **not take any parameters** and does **not return any value**.

/// Entry point of the Rust program.
///
/// # Notes
/// - `println!` is a **macro** that prints to the console.
/// - The `!` indicates that it is a macro, not a function.
/// - Macros can take arguments just like functions but are invoked with `!`.
/// - They do not always follow the same rules as functions, 
///   such as type inference and return types.
fn main() {
    println!("Hello, World!");
}
