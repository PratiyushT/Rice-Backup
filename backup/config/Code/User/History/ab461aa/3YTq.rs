use rand::Rng;
use std::{cmp::Ordering, io};

fn main() {
    /* Generating a random number between 0 and 100 */
    let rand_num = rand::thread_rng().gen_range(0..100);

    /* Tracking user error */
    let mut count = 0;

    /* Looping to continue the game. */
    loop {
        if count < 5 {

            /* Getting user's input */
            let mut input = String::new();
            io::stdin()
                .read_line(&mut input)
                .expect("Please enter a proper value");

            /* Prasing the input */
            let input: u64 = input
                .trim()
                .parse()
                .expect("Error parsing the input. Please enter a valid number");

            match input.cmp(&rand_num) {
                Ordering::Less => {
                    println!("The number you have guessed is too low. Guess higher!");
                    continue;
                }
                Ordering::Greater => println!("Too High!"),
                Ordering::Equal => println!("Perfect!"),
            }

            println!("You have guessed {} and the number is {}", input, rand_num);
        }
    }
}
