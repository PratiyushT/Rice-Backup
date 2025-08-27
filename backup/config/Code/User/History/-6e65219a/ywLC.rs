
// 1. Main function always gets called first in a Rust program
// 2. The main function must be declared as `fn main() {}`
// 3. The main function does not take any parameters and does not return any value.

fn main(){
    println!("Hello, World!"); 
    // `println!` is a macro that prints to the console.
    // The `!` indicates that it is a macro, not a function.
}