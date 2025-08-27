use rand::Rng;
use std::{cmp::Ordering, io};
use colored::Colorize;

fn main() {
    /* Generating a random number between 0 and 100 */
    let rand_num = rand::rng().random_range(0..100);

    /* Tracking user error */
    let mut count = 0;

    /* Looping to continue the game. */
    loop {
        if count < 5 {

            /* Getting user's input */
            println!("Guess the number (Press 'q' to quit): ".green());
            let mut input = String::new();
            io::stdin()
                .read_line(&mut input)
                .expect("Please enter a proper value");

            /* Prasing the input */
            let input: u64 = match input
                            .trim()
                            .parse() {
                Ok(num) => {
                    num
                },
                Err(_) => {
                    println!("Please enter a valid number.");
                    continue;
                },
            };

            /* Increase count only if parsing succeeds. */
            count += 1;

            /* Checking and mapping user's input to relevant situation */
            match input.cmp(&rand_num) {
                Ordering::Less => {
                    println!("The number you have guessed is too low. Guess higher!");
                    continue;
                }
                Ordering::Greater => {
                    println!("Too High!");
                    continue;
                }
                Ordering::Equal => {
                    println!("Perfect! You Win! You needed {count} tries to win!");
                    break;
                }
            }
        } else {
            println!("You have guesses wrong 5 times.\nThe correct number was {rand_num}.\nGame Over You Loser!!!!");
            break;
        }
    }
}
